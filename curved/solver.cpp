#include<assert.h>
#include<set>
#include<math.h>
#include<iostream>
#include<gmpxx.h>
#include<map>
#include<unordered_map>
#include<unordered_set>

typedef std::pair<mpz_class, mpz_class> P;

P O = P(-1, -1);
mpz_class PP;
const mpz_class two = 2;

inline mpz_class inv(mpz_class const &x) {
   static mpz_class r;
   mpz_invert(r.get_mpz_t(), x.get_mpz_t(), PP.get_mpz_t());
   return r;
}

inline mpz_class sq(mpz_class const &x) {
   static mpz_class r;
   mpz_powm(r.get_mpz_t(), x.get_mpz_t(), two.get_mpz_t(), PP.get_mpz_t());
   return r;
}

inline void eadd(P &a, P const &b) {
   if(b == O) {return;}
   if(a == O) {a=b; return;}

   static mpz_class x;
   static mpz_class l;
   if(a == b) {
      x = a.second << 1;
      mpz_invert(l.get_mpz_t(), x.get_mpz_t(), PP.get_mpz_t());
      l *= 3 * sq(a.first);
      l %= PP;
   } else {
      if(a.first == b.first) {a=O; return;}
      x = b.first - a.first;
      mpz_invert(l.get_mpz_t(), x.get_mpz_t(), PP.get_mpz_t());
      l *= (b.second - a.second);
      l %= PP;
   }
   x = sq(l) - a.first - b.first;
   x %= PP;
   if(x < 0) x += PP;

   a.second= (l * (a.first - x) - a.second) % PP;
   if(a.second < 0) a.second += PP;
   swap(x, a.first);
}

void emul(P &dst, P x, mpz_class n) {
   dst = O;
   while(n > 0) {
      if((n&1) == 1) eadd(dst, x);
      eadd(x, x);
      n >>= 1;
   }
}

struct Hash {
   typedef std::size_t result_type;
   std::size_t operator()(const P& key) const;
};

inline std::size_t Hash::operator()(const P& key) const {
   return std::hash<unsigned long>()(key.first.get_ui());
}

int main() {
   mpz_class Gx, Gy, Hx, Hy;

   std::cin >> PP;
   std::cin >> Gx >> Gy;
   std::cin >> Hx >> Hy;
   P G = P(Gx, Gy);
   P H = P(Hx, Hy);

   mpz_class n, t;
   std::cin >> n >> t;
   mpz_class m = sqrt(n) + 1;

   std::unordered_map<std::size_t, int> s;
   {
      P p = O, q;
      emul(q, G, t);
      for(int i=0; i<m; i++) {
         const size_t h = Hash()(p);
         s[h] = i;
         eadd(p, q);
         if(!(i%100000))
            std::cerr << "\x0d\033[K" << "[1 / 3] making hash set... " << 100.0*i/m << "% (" << h << ')' << std::flush;
      }
   }
   std::cerr << "\x0d\033[K" << "[1 / 3] making hash set... " << 100 << '%' << std::endl;

   std::set<mpz_class> u;
   {
      P a, c;
      emul(a, G, (t*(n-m)));
      emul(c, H, t);
      for(int i=0; i<m; i++) {
         const size_t h = Hash()(c);
         if(s.find(h) != s.end()) u.insert(s[h] + i*m);
         eadd(c, a);
         if(!(i%100000))
            std::cerr << "\x0d\033[K" << "[2 / 3] searching hash matching... " << 100.0*i/m << "% (" << h << ')' << std::flush;
      }
   }
   std::cerr << "\x0d\033[K" << "[2 / 3] searching hash matching... " << 100 << '%' << std::flush;

   std::cerr << std::endl;
   for(auto z: u) {
      P a, b;
      emul(a, G, t*z);
      emul(b, H, t);
      if(a == b)
         std::cout << "Mod(" << z << ", " << n << ")" << std::endl;
   }
   std::cerr << "\x0d\033[K" << "[3 / 3] checking exact matching... " << 100 << '%' << std::endl;

   return 0;
}
