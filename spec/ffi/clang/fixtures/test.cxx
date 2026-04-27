struct A {
  virtual int func_a() = 0;
  void takesARef(int& lValue, float&& rValue);
  void exceptionYes1();
  void exceptionNo1() noexcept;
  void exceptionYes2() noexcept(false);
  void exceptionNo2() noexcept(true);
  void exceptionThrow() throw;
  int int_member_a;
};

struct B : public virtual A {
  int func_a() { return 0; }

  static int func_b() { return 11; }
};

struct C : public virtual A {
  int func_a() { return 1; }

  enum { EnumC = 100 };
};

struct D : public B, public C {
 private:
  int func_a() { return B::func_a(); }
  void func_d();

  int private_member_int;
 public:
  int public_member_int;
 protected:
  int protected_member_int;
};

void D::func_d() {};
f_dynamic_call(A *a) { a->func_a(); };

void f_variadic(int a, ...);
void f_non_variadic(int a, char b, long c);

typedef int const* const_int_ptr;
typedef int** int_pp;
void takesPtrRefs(int*& pRef, int**& ppRef);
int int_array[8];

struct RefQualifier {
    void func_lvalue_ref() &;
    void func_rvalue_ref() &&;
    void func_none();
};

int A::*member_pointer = &A::int_member_a;

struct BitField {
  int bit_field_a : 2;
  int bit_field_b : 6;
  int non_bit_field_c;
};

enum normal_enum {
  normal_enum_a
};

template <typename T> T func_overloaded(T a) { return a;};
template <typename T> T func_overloaded() { return 100;};
template <typename T> T use_func_overloaded() { return func_overloaded<T>(); };
int use_overloaded_int_a = func_overloaded<int>();

void availability_func(void) __attribute__((availability(macosx,introduced=10.4.1,deprecated=10.6,obsoleted=10.7)));

namespace Outer
{
	namespace Inner
	{
		struct Nested();
	}
}