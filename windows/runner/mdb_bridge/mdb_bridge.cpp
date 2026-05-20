// windows/runner/mdb_bridge/mdb_bridge.cpp
#define UNICODE
#define _UNICODE
#include <windows.h>
#include <sql.h>
#include <sqlext.h>
#include <string>
#include <vector>
#include <sstream>

// Helper: convertit SQLCHAR* en std::string
static std::string toStr(SQLCHAR* s) { return std::string(reinterpret_cast<char*>(s)); }

// Helper: escape simple quote pour SQL
static std::string escapeSql(const std::string& s) {
    std::string out;
    for (char c : s) { if (c == '\'') out += '\''; out += c; }
    return out;
}

struct OdbcContext {
    SQLHENV hEnv = SQL_NULL_HANDLE;
    SQLHDBC hDbc = SQL_NULL_HANDLE;
    bool ok = false;

    OdbcContext(const char* mdbPath) {
        SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &hEnv);
        SQLSetEnvAttr(hEnv, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC3, 0);
        SQLAllocHandle(SQL_HANDLE_DBC, hEnv, &hDbc);

        std::string dsn =
                std::string("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=") +
                mdbPath + ";";

        SQLRETURN ret = SQLDriverConnectA(
                hDbc, NULL,
                (SQLCHAR*)dsn.c_str(), SQL_NTS,
                NULL, 0, NULL, SQL_DRIVER_NOPROMPT
        );
        ok = (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO);
    }

    ~OdbcContext() {
        if (hDbc != SQL_NULL_HANDLE) { SQLDisconnect(hDbc); SQLFreeHandle(SQL_HANDLE_DBC, hDbc); }
        if (hEnv != SQL_NULL_HANDLE) SQLFreeHandle(SQL_HANDLE_ENV, hEnv);
    }
};

// Copie sécurisée dans le buffer de sortie
static void safeCopy(const std::string& src, char* dst, int dstSize) {
    strncpy_s(dst, dstSize, src.c_str(), _TRUNCATE);
}

// ─── API exportée ──────────────────────────────────────────────

extern "C" {

// Retourne la liste des tables utilisateur, séparées par '\n'
__declspec(dllexport) int get_tables(const char* mdbPath, char* outBuf, int bufSize) {
    OdbcContext ctx(mdbPath);
    if (!ctx.ok) { safeCopy("ERROR:CONNECTION_FAILED", outBuf, bufSize); return -1; }

    SQLHSTMT hStmt;
    SQLAllocHandle(SQL_HANDLE_STMT, ctx.hDbc, &hStmt);

    SQLRETURN ret = SQLTablesA(hStmt, NULL, 0, NULL, 0, NULL, 0, (SQLCHAR*)"TABLE", SQL_NTS);
    if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
        SQLFreeHandle(SQL_HANDLE_STMT, hStmt);
        safeCopy("ERROR:TABLES_FAILED", outBuf, bufSize);
        return -1;
    }

    std::ostringstream oss;
    SQLCHAR tableName[256];
    SQLLEN ind;
    bool first = true;
    while (SQLFetch(hStmt) == SQL_SUCCESS) {
        SQLGetData(hStmt, 3, SQL_C_CHAR, tableName, sizeof(tableName), &ind);
        if (!first) oss << "\n";
        oss << toStr(tableName);
        first = false;
    }

    SQLFreeHandle(SQL_HANDLE_STMT, hStmt);
    safeCopy(oss.str(), outBuf, bufSize);
    return 0;
}

// Retourne colonnes d'une table : "col1|TYPE,col2|TYPE,..."
__declspec(dllexport) int get_columns(const char* mdbPath, const char* tableName, char* outBuf, int bufSize) {
    OdbcContext ctx(mdbPath);
    if (!ctx.ok) { safeCopy("ERROR:CONNECTION_FAILED", outBuf, bufSize); return -1; }

    SQLHSTMT hStmt;
    SQLAllocHandle(SQL_HANDLE_STMT, ctx.hDbc, &hStmt);

    SQLColumnsA(hStmt, NULL, 0, NULL, 0, (SQLCHAR*)tableName, SQL_NTS, NULL, 0);

    std::ostringstream oss;
    SQLCHAR colName[256], typeName[64];
    SQLLEN ind;
    bool first = true;
    while (SQLFetch(hStmt) == SQL_SUCCESS) {
        SQLGetData(hStmt, 4, SQL_C_CHAR, colName,  sizeof(colName),  &ind);
        SQLGetData(hStmt, 6, SQL_C_CHAR, typeName, sizeof(typeName), &ind);
        if (!first) oss << ",";
        oss << toStr(colName) << "|" << toStr(typeName);
        first = false;
    }

    SQLFreeHandle(SQL_HANDLE_STMT, hStmt);
    safeCopy(oss.str(), outBuf, bufSize);
    return 0;
}

// SELECT * FROM table → JSON array de rows
__declspec(dllexport) int select_all(const char* mdbPath, const char* tableName, char* outBuf, int bufSize) {
    OdbcContext ctx(mdbPath);
    if (!ctx.ok) { safeCopy("[]", outBuf, bufSize); return -1; }

    SQLHSTMT hStmt;
    SQLAllocHandle(SQL_HANDLE_STMT, ctx.hDbc, &hStmt);

    std::string sql = "SELECT * FROM [" + std::string(tableName) + "]";
    SQLExecDirectA(hStmt, (SQLCHAR*)sql.c_str(), SQL_NTS);

    SQLSMALLINT colCount;
    SQLNumResultCols(hStmt, &colCount);

    std::vector<std::string> colNames(colCount);
    for (SQLSMALLINT i = 1; i <= colCount; i++) {
        SQLCHAR name[256]; SQLSMALLINT nameLen;
        SQLDescribeColA(hStmt, i, name, sizeof(name), &nameLen, NULL, NULL, NULL, NULL);
        colNames[i - 1] = toStr(name);
    }

    std::ostringstream oss;
    oss << "[";
    bool firstRow = true;
    while (SQLFetch(hStmt) == SQL_SUCCESS) {
        if (!firstRow) oss << ",";
        oss << "{";
        for (SQLSMALLINT i = 1; i <= colCount; i++) {
            SQLCHAR val[1024]; SQLLEN ind;
            SQLRETURN r = SQLGetData(hStmt, i, SQL_C_CHAR, val, sizeof(val), &ind);
            if (i > 1) oss << ",";
            oss << "\"" << colNames[i-1] << "\":";
            if (ind == SQL_NULL_DATA || r != SQL_SUCCESS) oss << "null";
            else oss << "\"" << escapeSql(toStr(val)) << "\"";
        }
        oss << "}";
        firstRow = false;
    }
    oss << "]";

    SQLFreeHandle(SQL_HANDLE_STMT, hStmt);
    safeCopy(oss.str(), outBuf, bufSize);
    return 0;
}

// INSERT : colonnes et valeurs séparées par '|', paires par ','
// ex: "Nom|Alice,Age|30"
__declspec(dllexport) int insert_row(const char* mdbPath, const char* tableName, const char* colsVals, char* outBuf, int bufSize) {
    OdbcContext ctx(mdbPath);
    if (!ctx.ok) { safeCopy("ERROR:CONNECTION_FAILED", outBuf, bufSize); return -1; }

    // Parse "col1|val1,col2|val2"
    std::string cols, vals;
    std::string input(colsVals);
    std::istringstream ss(input);
    std::string pair;
    bool first = true;
    while (std::getline(ss, pair, ',')) {
        auto sep = pair.find('|');
        if (sep == std::string::npos) continue;
        std::string col = pair.substr(0, sep);
        std::string val = pair.substr(sep + 1);
        if (!first) { cols += ","; vals += ","; }
        cols += "[" + col + "]";
        vals += "'" + escapeSql(val) + "'";
        first = false;
    }

    std::string sql = "INSERT INTO [" + std::string(tableName) + "] (" + cols + ") VALUES (" + vals + ")";

    SQLHSTMT hStmt;
    SQLAllocHandle(SQL_HANDLE_STMT, ctx.hDbc, &hStmt);
    SQLRETURN ret = SQLExecDirectA(hStmt, (SQLCHAR*)sql.c_str(), SQL_NTS);
    SQLFreeHandle(SQL_HANDLE_STMT, hStmt);

    if (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO) {
        safeCopy("OK", outBuf, bufSize); return 0;
    }
    safeCopy("ERROR:INSERT_FAILED", outBuf, bufSize); return -1;
}

// UPDATE : pkCol|pkVal,col1|val1,col2|val2
__declspec(dllexport) int update_row(const char* mdbPath, const char* tableName,
                                     const char* pkCol, const char* pkVal, const char* colsVals, char* outBuf, int bufSize) {

    OdbcContext ctx(mdbPath);
    if (!ctx.ok) { safeCopy("ERROR:CONNECTION_FAILED", outBuf, bufSize); return -1; }

    std::string setClause;
    std::string input(colsVals);
    std::istringstream ss(input);
    std::string pair;
    bool first = true;
    while (std::getline(ss, pair, ',')) {
        auto sep = pair.find('|');
        if (sep == std::string::npos) continue;
        std::string col = pair.substr(0, sep);
        std::string val = pair.substr(sep + 1);
        if (!first) setClause += ",";
        setClause += "[" + col + "]='"+escapeSql(val)+"'";
        first = false;
    }

    std::string sql = "UPDATE [" + std::string(tableName) + "] SET " + setClause +
                      " WHERE [" + std::string(pkCol) + "]='" + escapeSql(pkVal) + "'";

    SQLHSTMT hStmt;
    SQLAllocHandle(SQL_HANDLE_STMT, ctx.hDbc, &hStmt);
    SQLRETURN ret = SQLExecDirectA(hStmt, (SQLCHAR*)sql.c_str(), SQL_NTS);
    SQLFreeHandle(SQL_HANDLE_STMT, hStmt);

    safeCopy(ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO ? "OK" : "ERROR:UPDATE_FAILED", outBuf, bufSize);
    return (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO) ? 0 : -1;
}

// DELETE
__declspec(dllexport) int delete_row(const char* mdbPath, const char* tableName,
                                     const char* pkCol, const char* pkVal, char* outBuf, int bufSize) {

    OdbcContext ctx(mdbPath);
    if (!ctx.ok) { safeCopy("ERROR:CONNECTION_FAILED", outBuf, bufSize); return -1; }

    std::string sql = "DELETE FROM [" + std::string(tableName) + "] WHERE [" +
                      std::string(pkCol) + "]='" + escapeSql(pkVal) + "'";

    SQLHSTMT hStmt;
    SQLAllocHandle(SQL_HANDLE_STMT, ctx.hDbc, &hStmt);
    SQLRETURN ret = SQLExecDirectA(hStmt, (SQLCHAR*)sql.c_str(), SQL_NTS);
    SQLFreeHandle(SQL_HANDLE_STMT, hStmt);

    safeCopy(ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO ? "OK" : "ERROR:DELETE_FAILED", outBuf, bufSize);
    return (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO) ? 0 : -1;
}

} // extern "C"