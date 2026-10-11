// modsections <umx file>: print where a song section of a Deus Ex music file starts, as a sub-song of OpenMPT
// and as an order position (what Galaxy does with GLX_SETPOSITION).
// Build it in the SurrealEngine folder, after the engine build:
//   cc -c ../tools/modstubs.c -o build/modstubs.o
//   c++ -std=c++17 ../tools/modsections.cpp build/modstubs.o -I Thirdparty/openmpt build/Thirdparty/openmpt/libopenmpt.a -o build/modsections
#include <libopenmpt/libopenmpt.hpp>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <sstream>
#include <vector>

int main(int argc, char** argv)
{
	std::ifstream f(argv[1], std::ios::binary);
	std::vector<char> data((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
	size_t start = std::string::npos;
	std::string all(data.begin(), data.end());
	for (const char* sig : { "IMPM", "Extended Module: " })
	{
		size_t pos = all.find(sig);
		if (pos != std::string::npos && pos < start) start = pos;
	}
	size_t scrm = all.find("SCRM");
	if (scrm != std::string::npos && scrm >= 44 && scrm - 44 < start) start = scrm - 44;
	if (start == std::string::npos) { printf("no module found\n"); return 1; }

	std::ostringstream log;
	std::vector<float> left(4410), right(4410);
	{
		openmpt::module mod(data.data() + start, data.size() - start, log);
		printf("%s: type %s, orders %d, patterns %d, subsongs %d\n", argv[1], mod.get_metadata("type").c_str(), mod.get_num_orders(), mod.get_num_patterns(), mod.get_num_subsongs());
	}
	for (int section = 0; section < 6; section++)
	{
		int subOrder = -1, subOrderAfter = -1, posOrderAfter = -1;
		{
			openmpt::module mod(data.data() + start, data.size() - start, log);
			if (section < mod.get_num_subsongs())
			{
				mod.select_subsong(section);
				subOrder = mod.get_current_order();
				mod.read(44100, left.size(), left.data(), right.data());
				subOrderAfter = mod.get_current_order();
			}
		}
		{
			openmpt::module mod(data.data() + start, data.size() - start, log);
			mod.set_position_order_row(section, 0);
			mod.read(44100, left.size(), left.data(), right.data());
			posOrderAfter = mod.get_current_order();
		}
		printf("  section %d: sub-song starts at order %d (plays order %d), position %d plays order %d\n", section, subOrder, subOrderAfter, section, posOrderAfter);
	}
	return 0;
}
