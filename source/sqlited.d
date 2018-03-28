module sqlited;

import std.string;
import etc.c.sqlite3;

class Connection {

    private {
         sqlite3* state; // No way to make this pointer const
    }

    this() {
        this(":memory:");
    }

    this(string file) {
        auto code = sqlite3_open(toStringz(file), &state);
        if(code != SQLITE_OK) {
            throw new Exception(fromStringz(sqlite3_errstr(code)).idup);
        }
    }
}