import sqlited;
import std.stdio;
import std.typecons;

void main() {
	auto a = scoped!Database;
	a.exec("create table test (x integer not null)");
	a.exec("insert into test values(3)");
	a.exec("insert into test values(1)");
	a.exec("insert into test values(-1)");
	a.exec("insert into test values(2)");
    foreach(x; a.query("select * from test where x > ?", 1)) {
        writeln(x[0]);
    }
	a.exec("drop table test");
}