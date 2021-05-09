// -*- c -*- \n

// This is a line comment. \n

/*
 * This is a block comment.
 */


int assert(int expected, int actual, char *code) {
  if (expected == actual) {
    printf("%s => %d\n", code, actual);
  } else {
    printf("%s => %d expected but got %d\n", code, expected, actual);
    exit(1);
  }
}

int g1;
int g2[4];

int ret3() {
  return 3;
  return 5;
}

int add2(int x, int y) {
  return x + y;
}

int sub2(int x, int y) {
  return x - y;
}

int add6(int a, int b, int c, int d, int e, int f) {
  return a + b + c + d + e + f;
}

int addx(int *x, int y) {
  return *x + y;
}

int sub_char(char a, char b, char c) {
  return a - b - c;
}

int fib(int x) {
  if (x<=1)
    return 1;
  return fib(x-1) + fib(x-2);
}

int main() {
  assert(8, ({ int a=3; int z=5; a+z; }), "int a=3; int z=5; a+z;");

  assert(0, 0, "0");
  assert(42, 42, "42");
  assert(5, 5, "0");
  assert(41,  12 + 34 - 5 , " 12 + 34 - 5 ");
  assert(5, 5, "0");
  assert(15, 5*(9-6), "5*(9-6)");
  assert(4, (3+5)/2, "(3+5)/2");
  assert(-10, -10, "0");
  assert(10, - -10, "- -10");
  assert(10, - - +10, "- - +10");

  assert(0, 0==1, "0==1");
  assert(1, 42==42, "42==42");
  assert(1, 0!=1, "0!=1");
  assert(0, 42!=42, "42!=42");

  assert(1, 0<1, "0<1");
  assert(0, 1<1, "1<1");
  assert(0, 2<1, "2<1");
  assert(1, 0<=1, "0<=1");
  assert(1, 1<=1, "1<=1");
  assert(0, 2<=1, "2<=1");

  assert(1, 1>0, "1>0");
  assert(0, 1>1, "1>1");
  assert(0, 1>2, "1>2");
  assert(1, 1>=0, "1>=0");
  assert(1, 1>=1, "1>=1");
  assert(0, 1>=2, "1>=2");

  assert(3, ({ int a; a=3; a; }), "int a; a=3; a;");
  assert(8, ({ int a; int z; a=3; z=5; a+z; }), "int a; int z; a=3; z=5; a+z;");
  assert(3, ({ int a=3; a; }), "int a=3; a;");
  assert(8, ({ int a=3; int z=5; a+z; }), "int a=3; int z=5; a+z;");

  assert(3, ({ int foo=3; foo; }), "int foo=3; foo;");
  assert(8, ({ int foo123=3; int bar=5; foo123+bar; }), "int foo123=3; int bar=5; foo123+bar;");

  assert(3, ret3(), "ret3();");

  assert(3, ({ int x=0; if (0) x=2; else x=3; x; }), "int x=0; if (0) x=2; else x=3; x;");
  assert(3, ({ int x=0; if (1-1) x=2; else x=3; x; }), "int x=0; if (1-1) x=2; else x=3; x;");
  assert(2, ({ int x=0; if (1) x=2; else x=3; x; }), "int x=0; if (1) x=2; else x=3; x;");
  assert(2, ({ int x=0; if (2-1) x=2; else x=3; x; }), "int x=0; if (2-1) x=2; else x=3; x;");

  assert(3, ({ 1; {2;} 3; }), "1; {2;} 3;");
  assert(10, ({ int i=0; i=0; while(i<10) i=i+1; i; }), "int i=0; i=0; while(i<10) i=i+1; i;");
  assert(55, ({ int i=0; int j=0; while(i<=10) {j=i+j; i=i+1;} j; }), "int i=0; int j=0; while(i<=10) {j=i+j; i=i+1;} j;");
  assert(55, ({ int i=0; int j=0; for (i=0; i<=10; i=i+1) j=i+j; j; }), "int i=0; int j=0; for (i=0; i<=10; i=i+1) j=i+j; j;");

  assert(8, add2(3, 5), "add(3, 5)");
  assert(2, sub2(5, 3), "sub(5, 3)");
  assert(21, add6(1,2,3,4,5,6), "add6(1,2,3,4,5,6)");
  assert(55, fib(9), "fib(9)");

  assert(3, ({ int x=3; *&x; }), "int x=3; *&x;");
  assert(3, ({ int x=3; int *y=&x; int **z=&y; **z; }), "int x=3; int *y=&x; int **z=&y; **z;");
  assert(5, ({ int x=3; int y=5; *(&x+1); }), "int x=3; int y=5; *(&x+1);");
  assert(5, ({ int x=3; int y=5; *(1+&x); }), "int x=3; int y=5; *(1+&x);");
  assert(3, ({ int x=3; int y=5; *(&y-1); }), "int x=3; int y=5; *(&y-1);");
  assert(5, ({ int x=3; int y=5; int *z=&x; *(z+1); }), "int x=3; int y=5; int *z=&x; *(z+1);");
  assert(3, ({ int x=3; int y=5; int *z=&y; *(z-1); }), "int x=3; int y=5; int *z=&y; *(z-1);");
  assert(5, ({ int x=3; int *y=&x; *y=5; x; }), "int x=3; int *y=&x; *y=5; x;");
  assert(7, ({ int x=3; int y=5; *(&x+1)=7; y; }), "int x=3; int y=5; *(&x+1)=7; y;");
  assert(7, ({ int x=3; int y=5; *(&y-1)=7; x; }), "int x=3; int y=5; *(&y-1)=7; x;");
  assert(8, ({ int x=3; int y=5; addx(&x, y); }), "int x=3; int y=5; addx(&x, y);");

  assert(3, ({ int x[2]; int *y=&x; *y=3; *x; }), "int x[2]; int *y=&x; *y=3; *x;");

  assert(3, ({ int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *x; }), "int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *x;");
  assert(4, ({ int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *(x+1); }), "int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *(x+1);");
  assert(5, ({ int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *(x+2); }), "int x[3]; *x=3; *(x+1)=4; *(x+2)=5; *(x+2);");

  assert(0, ({ int x[2][3]; int *y=x; *y=0; **x; }), "int x[2][3]; int *y=x; *y=0; **x;");
  assert(1, ({ int x[2][3]; int *y=x; *(y+1)=1; *(*x+1); }), "int x[2][3]; int *y=x; *(y+1)=1; *(*x+1);");
  assert(2, ({ int x[2][3]; int *y=x; *(y+2)=2; *(*x+2); }), "int x[2][3]; int *y=x; *(y+2)=2; *(*x+2);");
  assert(3, ({ int x[2][3]; int *y=x; *(y+3)=3; **(x+1); }), "int x[2][3]; int *y=x; *(y+3)=3; **(x+1);");
  assert(4, ({ int x[2][3]; int *y=x; *(y+4)=4; *(*(x+1)+1); }), "int x[2][3]; int *y=x; *(y+4)=4; *(*(x+1)+1);");
  assert(5, ({ int x[2][3]; int *y=x; *(y+5)=5; *(*(x+1)+2); }), "int x[2][3]; int *y=x; *(y+5)=5; *(*(x+1)+2);");
  assert(6, ({ int x[2][3]; int *y=x; *(y+6)=6; **(x+2); }), "int x[2][3]; int *y=x; *(y+6)=6; **(x+2);");

  assert(3, ({ int x[3]; *x=3; x[1]=4; x[2]=5; *x; }), "int x[3]; *x=3; x[1]=4; x[2]=5; *x;");
  assert(4, ({ int x[3]; *x=3; x[1]=4; x[2]=5; *(x+1); }), "int x[3]; *x=3; x[1]=4; x[2]=5; *(x+1);");
  assert(5, ({ int x[3]; *x=3; x[1]=4; x[2]=5; *(x+2); }), "int x[3]; *x=3; x[1]=4; x[2]=5; *(x+2);");
  assert(5, ({ int x[3]; *x=3; x[1]=4; x[2]=5; *(x+2); }), "int x[3]; *x=3; x[1]=4; x[2]=5; *(x+2);");
  assert(5, ({ int x[3]; *x=3; x[1]=4; 2[x]=5; *(x+2); }), "int x[3]; *x=3; x[1]=4; 2[x]=5; *(x+2);");

  assert(0, ({ int x[2][3]; int *y=x; y[0]=0; x[0][0]; }), "int x[2][3]; int *y=x; y[0]=0; x[0][0];");
  assert(1, ({ int x[2][3]; int *y=x; y[1]=1; x[0][1]; }), "int x[2][3]; int *y=x; y[1]=1; x[0][1];");
  assert(2, ({ int x[2][3]; int *y=x; y[2]=2; x[0][2]; }), "int x[2][3]; int *y=x; y[2]=2; x[0][2];");
  assert(3, ({ int x[2][3]; int *y=x; y[3]=3; x[1][0]; }), "int x[2][3]; int *y=x; y[3]=3; x[1][0];");
  assert(4, ({ int x[2][3]; int *y=x; y[4]=4; x[1][1]; }), "int x[2][3]; int *y=x; y[4]=4; x[1][1];");
  assert(5, ({ int x[2][3]; int *y=x; y[5]=5; x[1][2]; }), "int x[2][3]; int *y=x; y[5]=5; x[1][2];");
  assert(6, ({ int x[2][3]; int *y=x; y[6]=6; x[2][0]; }), "int x[2][3]; int *y=x; y[6]=6; x[2][0];");

  assert(8, ({ int x; sizeof(x); }), "int x; sizeof(x);");
  assert(8, ({ int x; sizeof x; }), "int x; sizeof x;");
  assert(8, ({ int *x; sizeof(x); }), "int *x; sizeof(x);");
  assert(32, ({ int x[4]; sizeof(x); }), "int x[4]; sizeof(x);");
  assert(96, ({ int x[3][4]; sizeof(x); }), "int x[3][4]; sizeof(x);");
  assert(32, ({ int x[3][4]; sizeof(*x); }), "int x[3][4]; sizeof(*x);");
  assert(8, ({ int x[3][4]; sizeof(**x); }), "int x[3][4]; sizeof(**x);");
  assert(9, ({ int x[3][4]; sizeof(**x) + 1; }), "int x[3][4]; sizeof(**x) + 1;");
  assert(9, ({ int x[3][4]; sizeof **x + 1; }), "int x[3][4]; sizeof **x + 1;");
  assert(8, ({ int x[3][4]; sizeof(**x + 1); }), "int x[3][4]; sizeof(**x + 1);");

  assert(0, g1, "g1");
  g1=3;
  assert(3, g1, "g1");

  g2[0]=0; g2[1]=1; g2[2]=2; g2[3]=3;
  assert(0, g2[0], "g2[0]");
  assert(1, g2[1], "g2[1]");
  assert(2, g2[2], "g2[2]");
  assert(3, g2[3], "g2[3]");

  assert(8, sizeof(g1), "sizeof(g1)");
  assert(32, sizeof(g2), "sizeof(g2)");

  assert(1, ({ char x=1; x; }), "char x=1; x;");
  assert(1, ({ char x=1; char y=2; x; }), "char x=1; char y=2; x;");
  assert(2, ({ char x=1; char y=2; y; }), "char x=1; char y=2; y;");

  assert(1, ({ char x; sizeof(x); }), "char x; sizeof(x);");
  assert(10, ({ char x[10]; sizeof(x); }), "char x[10]; sizeof(x);");
  assert(1, sub_char(7, 3, 3), "sub_char(7, 3, 3)");

  assert(97, "abc"[0], "\"abc\"[0]");
  assert(98, "abc"[1], "\"abc\"[1]");
  assert(99, "abc"[2], "\"abc\"[2]");
  assert(0, "abc"[3], "\"abc\"[3]");
  assert(4, sizeof("abc"), "sizeof(\"abc\")");

  assert(7, "\a"[0], "\"\\a\"[0]");
  assert(8, "\b"[0], "\"\\b\"[0]");
  assert(9, "\t"[0], "\"\\t\"[0]");
  assert(10, "\n"[0], "\"\\n\"[0]");
  assert(11, "\v"[0], "\"\\v\"[0]");
  assert(12, "\f"[0], "\"\\f\"[0]");
  assert(13, "\r"[0], "\"\\r\"[0]");
  assert(27, "\e"[0], "\"\\e\"[0]");
  assert(0, "\0"[0], "\"\\0\"[0]");

  assert(106, "\j"[0], "\"\\j\"[0]");
  assert(107, "\k"[0], "\"\\k\"[0]");
  assert(108, "\l"[0], "\"\\l\"[0]");

  assert(2, ({ int x=2; { int x=3; } x; }), "int x=2; { int x=3; } x;");
  assert(2, ({ int x=2; { int x=3; } int y=4; x; }), "int x=2; { int x=3; } int y=4; x;");
  assert(3, ({ int x=2; { x=3; } x; }), "int x=2; { x=3; } x;");

  assert(1, ({ struct {int a; int b;} x; x.a=1; x.b=2; x.a; }), "struct {int a; int b;} x; x.a=1; x.b=2; x.a;");
  assert(2, ({ struct {int a; int b;} x; x.a=1; x.b=2; x.b; }), "struct {int a; int b;} x; x.a=1; x.b=2; x.b;");
  assert(1, ({ struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.a; }), "struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.a;");
  assert(2, ({ struct {char a; int b; char c;} x; x.b=1; x.b=2; x.c=3; x.b; }), "struct {char a; int b; char c;} a; x.b=x; x.a=2; x.b=3; x.b;");
  assert(3, ({ struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.c; }), "struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.c;");

  assert(0, ({ struct {int a; int b;} x[3]; int *p=x; p[0]=0; x[0].a; }), "struct {int a; int b;} x[3]; int *p=x; p[0]=0; x[0].a;");
  assert(1, ({ struct {int a; int b;} x[3]; int *p=x; p[1]=1; x[0].b; }), "struct {int a; int b;} x[3]; int *p=x; p[1]=1; x[0].b;");
  assert(2, ({ struct {int a; int b;} x[3]; int *p=x; p[2]=2; x[1].a; }), "struct {int a; int b;} x[3]; int *p=x; p[2]=2; x[1].a;");
  assert(3, ({ struct {int a; int b;} x[3]; int *p=x; p[3]=3; x[1].b; }), "struct {int a; int b;} x[3]; int *p=x; p[3]=3; x[1].b;");

  assert(6, ({ struct {int a[3]; int b[5];} x; int *p=&x; x.a[0]=6; p[0]; }), "struct {int a[3]; int b[5];} x; int *p=&x; x.a[0]=6; p[0];");
  assert(7, ({ struct {int a[3]; int b[5];} x; int *p=&x; x.b[0]=7; p[3]; }), "struct {int a[3]; int b[5];} x; int *p=&x; x.b[0]=7; p[3];");

  assert(6, ({ struct { struct { int b; } a; } x; x.a.b=6; x.a.b; }), "struct { struct { int b; } a; } x; x.a.b=6; x.a.b;");

  assert(8, ({ struct {int a;} x; sizeof(x); }), "struct {int a;} x; sizeof(x);");
  assert(16, ({ struct {int a; int b;} x; sizeof(x); }), "struct {int a; int b;} x; sizeof(x);");
  assert(24, ({ struct {int a[3];} x; sizeof(x); }), "struct {int a[3];} x; sizeof(x);");
  assert(32, ({ struct {int a;} x[4]; sizeof(x); }), "struct {int a;} x[4]; sizeof(x);");
  assert(48, ({ struct {int a[3];} x[2]; sizeof(x); }), "struct {int a[3];} x[2]; sizeof(x)};");
  assert(2, ({ struct {char a; char b;} x; sizeof(x); }), "struct {char a; char b;} x; sizeof(x);");
  // assert(9, ({ struct {char a; int b;} x; sizeof(x); }), "struct {char a; int b;} x; sizeof(x);"); これはメンバ変数のスタック上のメモリ配置を考慮していない \n

  // check error \n
  // assert(6, ({ struct { struct { int b; } a; } x; x.a.b=6; x.a.c; }), "struct { struct { int b; } a; } x; x.a.b=6; x.a.b;"); \n

  // コンパイラが行うアライメントを実装 \n
  assert(16, ({ struct {char a; int b;} x; sizeof(x); }), "struct {char a; int b;} x; sizeof(x);");
  assert(16, ({ struct {int a; char b;} x; sizeof(x); }), "struct {int a; char b;} x; sizeof(x);");

  // ローカル変数もアライメント \n
  assert(15, ({ int x; char y; int a=&x; int b=&y; b-a; }), "int x; char y; int a=&x; int b=&y; b-a;");
  assert(1, ({ char x; int y; int a=&x; int b=&y; b-a; }), "char x; int y; int a=&x; int b=&y; b-a;");
  assert(1, ({ char x; char y; int a=&x; int b=&y; b-a; }), "char x; int y; int a=&x; int b=&y; b-a;");
  assert(8, ({ int x; int y; int a=&x; int b=&y; b-a; }), "char x; int y; int a=&x; int b=&y; b-a;");
  assert(23, ({ int x; int y; char z; int a=&x; int b=&y; int c=&z; c-a; }), "char x; int y; int a=&x; int b=&y; b-a;");
  assert(15, ({ int x; int y; char z; int a=&x; int b=&y; int c=&z; c-b; }), "char x; int y; int a=&x; int b=&y; b-a;");
  assert(8, ({ int x; int y; char z; int a=&x; int b=&y; int c=&z; b-a; }), "char x; int y; int a=&x; int b=&y; b-a;");

  assert(24, ({ int x; int y; char z; int g; int a=&x; int b=&y; int c=&z; int d=&g; d-a; }), "char x; int y; int a=&x; int b=&y; b-a;");
  assert(23, ({ int x; int y; char z; char g; int a=&x; int b=&y; int c=&z; int d=&g; d-a; }), "char x; int y; int a=&x; int b=&y; b-a;");

  assert(16, ({ int x; int y; int z; int a=&x; int b=&y; int c=&z; c-a; }), "char x; int y; int a=&x; int b=&y; b-a;");
  // assert(16, ({ int x; char y; int a=&x; int b=&y; b; }), "int x; char y; int a=&x; int b=&y; b-a;"); -> 変な数字（アドレス）になる \n

    assert(16, ({ struct t {int a; int b;} x; struct t y; sizeof(y); }), "struct t {int a; int b;} x; struct t y; sizeof(y);");
  assert(16, ({ struct t {int a; int b;}; struct t y; sizeof(y); }), "struct t {int a; int b;}; struct t y; sizeof(y);");
  assert(2, ({ struct t {char a[2];}; { struct t {char a[4];}; } struct t y; sizeof(y); }), "struct t {char a[2];}; { struct t {char a[4];}; } struct t y; sizeof(y);");
  assert(3, ({ struct t {int x;}; int t=1; struct t y; y.x=2; t+y.x; }), "struct t {int x;}; int t=1; struct t y; y.x=2; t+y.x;");

  printf("OK\n");
  return 0;
}
