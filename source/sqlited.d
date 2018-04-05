module sqlited;


import std.stdio;
import std.string;
import std.variant;
import std.typecons;
import etc.c.sqlite3;


private void fail(int code) {
    throw new Exception(fromStringz(sqlite3_errstr(code)).idup);
}


class Database {

    private sqlite3* state; // No way to make this pointer const

    this() {
        this(":memory:");
    }

    this(string file) {
        auto code = sqlite3_open(toStringz(file), &state);
        if(code != SQLITE_OK) fail(code);
    }

    ~this() {
        sqlite3_close_v2(state);
    }

    private void bind(T...)(sqlite3_stmt* stmt, T args) {
        int code, i = 1;
        static foreach(x; args) {
            static if(is(typeof(x): int) || is(typeof(x): bool)) {
                code = sqlite3_bind_int(stmt, i++, x);
            } else static if(is(typeof(x) : long)) {
                code = sqlite3_bind_int64(stmt, i++, x);
            } else static if(is(typeof(x) : float) || is(typeof(x) : double)) {
                code = sqlite3_bind_double(stmt, i++, x);
            } else static if(is(typeof(x) : string)) {
                code = sqlite3_bind_text(stmt, i++, toStringz(x), -1, SQLITE_TRANSIENT);
            } else static if(typeid(x) == typeid(null)) {
                code = sqlite3_bind_null(stmt, i++);
            } else {
                static assert(0);
            }
        }
    }

    Result query(T...)(string sql, T args) {
        sqlite3_stmt* stmt;
        const char* tail = null;
        auto code = sqlite3_prepare_v2(state, toStringz(sql), -1, &stmt, &tail);
        if(code != SQLITE_OK) fail(code);
        bind(stmt, args);
        return Result(stmt);
    }

    void exec(T...)(string sql, T args) {
        auto code = sqlite3_exec(state, toStringz(sql), null, null, null);
        if(code != SQLITE_OK) fail(code);
    }
}


struct Result {

    private {
        sqlite3_stmt* stmt;
        bool done = false;
        Row row;
    }

    package this(sqlite3_stmt* stmt) {
        this.stmt = stmt;
        row = Row(stmt);
        popFront();
    }

    ~this() {
        sqlite3_finalize(stmt);
    }

    bool empty() {
        return done;
    }

    void popFront() {
        if(!done) {
            auto code = sqlite3_step(stmt);
            switch(code) {
                case SQLITE_ROW: break; // done = false; <-- handled by the above if()
                case SQLITE_DONE: done = true; break;
                default: fail(code);
            }
        }
    }

    Row front() {
        return row;
    }
}


alias Typedef!(string) BLOB;


alias Algebraic!(typeof(null), long, double, string, BLOB) Column;


struct Row {

    private sqlite3_stmt* stmt;

    package this(sqlite3_stmt* stmt) {
        this.stmt = stmt;
    }

    @property size_t length() {
        return sqlite3_column_count(stmt);
    }

    Column opIndex(int column) in {
        assert(column < this.length);
    } do {
        switch(sqlite3_column_type(stmt, column)) {
            case SQLITE_NULL:
                return Column(null);
            case SQLITE_INTEGER:
                return Column(sqlite3_column_int64(stmt, column));
            case SQLITE_FLOAT:
                return Column(sqlite3_column_double(stmt, column));
            case SQLITE3_TEXT:
                return Column(fromStringz(sqlite3_column_text(stmt, column)).idup);
            case SQLITE_BLOB:
                return Column(BLOB(fromStringz(sqlite3_column_text(stmt, column)).idup));
            default:
                throw new Exception("Unknown SQLite datatype encountered"); // FIXME
        }
    }
}