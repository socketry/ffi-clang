template<typename T, int Count, bool Enabled>
struct MixedArgs {
};

template<>
struct MixedArgs<float, -7, true> {
};

template<unsigned long long Value>
struct UnsignedArg {
};

template<>
struct UnsignedArg<2147483649ULL> {
};

template<typename T, int Count, bool Enabled>
void specialized_func() {
}

template<>
void specialized_func<double, 42, false>() {
}
