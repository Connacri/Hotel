#include "access_mdb_reader.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <sqlext.h>

#include <algorithm>
#include <cctype>
#include <memory>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr auto kChannelName = "hotel/native_mdb_reader";

void LogDebug(const std::wstring& message) {
  const std::wstring output = L"[MDB Import] " + message + L"\n";
  OutputDebugStringW(output.c_str());
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }

  const int size_needed = MultiByteToWideChar(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0);
  std::wstring wide(size_needed, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      wide.data(), size_needed);
  return wide;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }

  const int size_needed = WideCharToMultiByte(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0,
      nullptr, nullptr);
  std::string utf8(size_needed, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      utf8.data(), size_needed, nullptr, nullptr);
  return utf8;
}

std::wstring EscapeConnectionValue(const std::wstring& value) {
  std::wstring escaped = L"{";
  for (const auto ch : value) {
    if (ch == L'}') {
      escaped += L"}}";
    } else {
      escaped += ch;
    }
  }
  escaped += L"}";
  return escaped;
}

bool IsSafeIdentifier(const std::string& value) {
  if (value.empty()) {
    return false;
  }

  for (const unsigned char ch : value) {
    if (!std::isalnum(ch) && ch != '_') {
      return false;
    }
  }
  return true;
}

std::string ReadDiagnostics(SQLSMALLINT handle_type, SQLHANDLE handle) {
  std::ostringstream stream;
  SQLSMALLINT record = 1;

  while (true) {
    SQLWCHAR state[6] = {0};
    SQLINTEGER native_error = 0;
    SQLWCHAR message[1024] = {0};
    SQLSMALLINT message_length = 0;

    const SQLRETURN result = SQLGetDiagRecW(handle_type, handle, record, state,
                                            &native_error, message,
                                            sizeof(message) / sizeof(SQLWCHAR),
                                            &message_length);
    if (result == SQL_NO_DATA) {
      break;
    }
    if (!SQL_SUCCEEDED(result)) {
      break;
    }

    if (record > 1) {
      stream << '\n';
    }
    stream << '[' << WideToUtf8(reinterpret_cast<wchar_t*>(state)) << "] "
           << WideToUtf8(reinterpret_cast<wchar_t*>(message));
    if (native_error != 0) {
      stream << " (code " << native_error << ')';
    }
    record++;
  }

  return stream.str();
}

class AccessConnection {
 public:
  AccessConnection() = default;

  ~AccessConnection() { Close(); }

  void Open(const std::wstring& path) {
    LogDebug(L"Opening MDB through native ODBC.");
    AllocateHandles();

    const std::wstring escaped_path = EscapeConnectionValue(path);
    const std::vector<std::wstring> connection_attempts = {
        L"Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=" +
            escaped_path + L";Uid=Admin;Pwd=;ReadOnly=1;",
        L"Driver={Microsoft Access Driver (*.mdb)};DBQ=" + escaped_path +
            L";Uid=Admin;Pwd=;ReadOnly=1;",
    };

    std::vector<std::string> errors;
    for (const auto& connection_string : connection_attempts) {
      SQLWCHAR output[1024] = {0};
      SQLSMALLINT output_length = 0;
      const SQLRETURN result = SQLDriverConnectW(
          dbc_, nullptr,
          reinterpret_cast<SQLWCHAR*>(const_cast<wchar_t*>(
              connection_string.c_str())),
          SQL_NTS, output, sizeof(output) / sizeof(SQLWCHAR), &output_length,
          SQL_DRIVER_NOPROMPT);
      if (SQL_SUCCEEDED(result)) {
        is_connected_ = true;
        LogDebug(L"Native ODBC connection established.");
        return;
      }

      const std::string diagnostic = ReadDiagnostics(SQL_HANDLE_DBC, dbc_);
      if (!diagnostic.empty()) {
        errors.push_back(diagnostic);
      }
    }

    std::ostringstream message;
    message
        << "Impossible d'ouvrir la base Access via le pilote Windows natif.\n"
        << "Installez le pilote ODBC Microsoft Access si le systeme n'en "
           "dispose pas.";
    if (!errors.empty()) {
      message << "\n\nDiagnostics ODBC :";
      for (const auto& error : errors) {
        message << "\n- " << error;
      }
    }
    throw std::runtime_error(message.str());
  }

  std::vector<std::vector<std::optional<std::string>>> ReadTable(
      const std::string& table_name) {
    if (!IsSafeIdentifier(table_name)) {
      throw std::runtime_error("Nom de table invalide.");
    }

    SQLHSTMT stmt = SQL_NULL_HSTMT;
    if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_STMT, dbc_, &stmt))) {
      throw std::runtime_error(
          "Impossible d'allouer un handle SQL pour la lecture MDB.");
    }

    const auto cleanup_stmt = [&stmt]() {
      if (stmt != SQL_NULL_HSTMT) {
        SQLFreeHandle(SQL_HANDLE_STMT, stmt);
        stmt = SQL_NULL_HSTMT;
      }
    };

    try {
      LogDebug(L"Reading table " + Utf8ToWide(table_name) + L" through native ODBC.");
      const std::wstring query =
          L"SELECT * FROM [" + Utf8ToWide(table_name) + L"]";
      const SQLRETURN exec_result = SQLExecDirectW(
          stmt,
          reinterpret_cast<SQLWCHAR*>(const_cast<wchar_t*>(query.c_str())),
          SQL_NTS);
      if (!SQL_SUCCEEDED(exec_result)) {
        throw std::runtime_error(
            "Lecture MDB impossible pour la table '" + table_name + "'.\n" +
            ReadDiagnostics(SQL_HANDLE_STMT, stmt));
      }

      SQLSMALLINT column_count = 0;
      if (!SQL_SUCCEEDED(SQLNumResultCols(stmt, &column_count))) {
        throw std::runtime_error(
            "Impossible de lire le schema de la table '" + table_name + "'.");
      }

      std::vector<std::vector<std::optional<std::string>>> rows;
      while (true) {
        const SQLRETURN fetch_result = SQLFetch(stmt);
        if (fetch_result == SQL_NO_DATA) {
          break;
        }
        if (!SQL_SUCCEEDED(fetch_result)) {
          throw std::runtime_error(
              "Erreur de parcours de la table '" + table_name + "'.\n" +
              ReadDiagnostics(SQL_HANDLE_STMT, stmt));
        }

        std::vector<std::optional<std::string>> row;
        row.reserve(column_count);
        for (SQLUSMALLINT column = 1; column <= column_count; ++column) {
          row.push_back(ReadColumn(stmt, column));
        }
        rows.push_back(std::move(row));
      }

      LogDebug(L"Native ODBC read completed for table " + Utf8ToWide(table_name) +
               L".");
      cleanup_stmt();
      return rows;
    } catch (...) {
      cleanup_stmt();
      throw;
    }
  }

 private:
  void AllocateHandles() {
    if (env_ == SQL_NULL_HENV) {
      if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE,
                                        &env_))) {
        throw std::runtime_error(
            "Impossible d'initialiser l'environnement ODBC.");
      }
      if (!SQL_SUCCEEDED(SQLSetEnvAttr(
              env_, SQL_ATTR_ODBC_VERSION,
              reinterpret_cast<SQLPOINTER>(SQL_OV_ODBC3), 0))) {
        throw std::runtime_error("Impossible de configurer ODBC v3.");
      }
    }

    if (dbc_ == SQL_NULL_HDBC) {
      if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_DBC, env_, &dbc_))) {
        throw std::runtime_error(
            "Impossible d'initialiser la connexion ODBC.");
      }
    }
  }

  std::optional<std::string> ReadColumn(SQLHSTMT stmt, SQLUSMALLINT column) {
    std::wstring value;
    SQLLEN indicator = 0;
    SQLWCHAR buffer[1024] = {0};

    while (true) {
      std::fill(std::begin(buffer), std::end(buffer), static_cast<SQLWCHAR>(0));
      const SQLRETURN result =
          SQLGetData(stmt, column, SQL_C_WCHAR, buffer, sizeof(buffer),
                     &indicator);

      if (indicator == SQL_NULL_DATA) {
        return std::nullopt;
      }
      if (result == SQL_NO_DATA) {
        break;
      }
      if (!(SQL_SUCCEEDED(result) || result == SQL_SUCCESS_WITH_INFO)) {
        throw std::runtime_error("Erreur de lecture d'une colonne MDB.");
      }

      value.append(reinterpret_cast<wchar_t*>(buffer));
      if (result == SQL_SUCCESS) {
        break;
      }
    }

    return WideToUtf8(value);
  }

  void Close() {
    if (dbc_ != SQL_NULL_HDBC) {
      if (is_connected_) {
        SQLDisconnect(dbc_);
        is_connected_ = false;
      }
      SQLFreeHandle(SQL_HANDLE_DBC, dbc_);
      dbc_ = SQL_NULL_HDBC;
    }
    if (env_ != SQL_NULL_HENV) {
      SQLFreeHandle(SQL_HANDLE_ENV, env_);
      env_ = SQL_NULL_HENV;
    }
  }

  SQLHENV env_ = SQL_NULL_HENV;
  SQLHDBC dbc_ = SQL_NULL_HDBC;
  bool is_connected_ = false;
};

const std::string* GetStringArgument(const EncodableMap& arguments,
                                     const char* key) {
  const auto it = arguments.find(EncodableValue(key));
  if (it == arguments.end()) {
    return nullptr;
  }
  return std::get_if<std::string>(&it->second);
}

EncodableList EncodeRows(
    const std::vector<std::vector<std::optional<std::string>>>& rows) {
  EncodableList encoded_rows;
  encoded_rows.reserve(rows.size());

  for (const auto& row : rows) {
    EncodableList encoded_row;
    encoded_row.reserve(row.size());
    for (const auto& column : row) {
      if (column.has_value()) {
        encoded_row.emplace_back(column.value());
      } else {
        encoded_row.emplace_back();
      }
    }
    encoded_rows.emplace_back(std::move(encoded_row));
  }

  return encoded_rows;
}

}  // namespace

void RegisterNativeMdbReader(flutter::BinaryMessenger* messenger) {
  auto channel =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger, kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        const auto* arguments = std::get_if<EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments",
                        "Les arguments de la migration MDB sont invalides.");
          return;
        }

        const std::string* path = GetStringArgument(*arguments, "path");
        if (path == nullptr || path->empty()) {
          result->Error("invalid_path", "Le chemin MDB est manquant.");
          return;
        }

        try {
          LogDebug(L"Received native MDB method call.");
          AccessConnection connection;
          connection.Open(Utf8ToWide(*path));

          if (call.method_name() == "checkAccessSupport") {
            result->Success();
            return;
          }

          if (call.method_name() == "readTable") {
            const std::string* table = GetStringArgument(*arguments, "table");
            if (table == nullptr || table->empty()) {
              result->Error("invalid_table",
                            "Le nom de table MDB est manquant.");
              return;
            }

            result->Success(EncodeRows(connection.ReadTable(*table)));
            return;
          }

          result->NotImplemented();
        } catch (const std::exception& exception) {
          LogDebug(L"Native MDB method call failed.");
          result->Error("mdb_native_error", exception.what());
        }
      });
}
