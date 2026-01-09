// simdjson native benchmark - Full DOM traversal (comparable to mojson)
// Compile: clang++ -O3 -std=c++17 -o bench_simdjson bench_simdjson.cpp -I$CONDA_PREFIX/include -L$CONDA_PREFIX/lib -lsimdjson

#include <iostream>
#include <fstream>
#include <sstream>
#include <chrono>
#include <vector>
#include <string>
#include "simdjson.h"

// Count all values by traversing the DOM (similar to what mojson does)
size_t traverse_element(simdjson::dom::element elem)
{
    size_t count = 1;
    switch (elem.type())
    {
    case simdjson::dom::element_type::ARRAY:
        for (auto child : elem.get_array().value())
        {
            count += traverse_element(child);
        }
        break;
    case simdjson::dom::element_type::OBJECT:
        for (auto [key, value] : elem.get_object().value())
        {
            (void)key; // Access key (like mojson extracts keys)
            count += traverse_element(value);
        }
        break;
    case simdjson::dom::element_type::STRING:
        (void)elem.get_string().value(); // Access string data
        break;
    case simdjson::dom::element_type::INT64:
        (void)elem.get_int64().value();
        break;
    case simdjson::dom::element_type::UINT64:
        (void)elem.get_uint64().value();
        break;
    case simdjson::dom::element_type::DOUBLE:
        (void)elem.get_double().value();
        break;
    case simdjson::dom::element_type::BOOL:
        (void)elem.get_bool().value();
        break;
    default:
        break;
    }
    return count;
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        std::cerr << "Usage: " << argv[0] << " <json_file>" << std::endl;
        return 1;
    }

    std::string filepath = argv[1];

    // Read file
    std::ifstream file(filepath);
    if (!file)
    {
        std::cerr << "Error: Cannot open file " << filepath << std::endl;
        return 1;
    }
    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string json_str = buffer.str();
    size_t file_size = json_str.size();

    std::cout << "\n--- simdjson native (C++) - Full DOM Traversal ---" << std::endl;
    std::cout << "File: " << filepath << std::endl;
    std::cout << "Size: " << file_size << " bytes (" << (file_size / 1024.0) << " KB)" << std::endl;
    std::cout << std::endl;

    // Use DOM parser which builds full tree (like mojson)
    simdjson::dom::parser parser;

    // Warmup
    for (int i = 0; i < 3; i++)
    {
        auto doc = parser.parse(json_str);
        traverse_element(doc.value());
    }

    // Benchmark
    int num_iters = 100;
    std::vector<double> times;
    times.reserve(num_iters);
    size_t total_nodes = 0;

    for (int i = 0; i < num_iters; i++)
    {
        auto start = std::chrono::high_resolution_clock::now();
        auto doc = parser.parse(json_str);
        total_nodes = traverse_element(doc.value());
        auto end = std::chrono::high_resolution_clock::now();

        double elapsed_ms = std::chrono::duration<double, std::milli>(end - start).count();
        times.push_back(elapsed_ms);
    }

    // Calculate stats
    double min_time = times[0], max_time = times[0], total_time = 0;
    for (double t : times)
    {
        if (t < min_time)
            min_time = t;
        if (t > max_time)
            max_time = t;
        total_time += t;
    }
    double avg_time = total_time / num_iters;
    double throughput = (file_size / 1e9) / (min_time / 1000.0);

    std::cout << "Nodes:      " << total_nodes << std::endl;
    std::cout << "Iterations: " << num_iters << std::endl;
    std::cout << "Min time:   " << min_time << " ms" << std::endl;
    std::cout << "Avg time:   " << avg_time << " ms" << std::endl;
    std::cout << "Max time:   " << max_time << " ms" << std::endl;
    std::cout << "Throughput: " << throughput << " GB/s" << std::endl;

    return 0;
}
