import std.stdio;
import sqlited;
import std.typecons;

void main() {
	auto a = scoped!Database;
	a.statement("create table test(x integer not null)");
	a.statement("insert into test values(null)");
	a.statement("drop table test");
}