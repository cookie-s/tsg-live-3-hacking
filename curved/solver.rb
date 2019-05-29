require 'test/unit/assertions'
require 'pry'
include Test::Unit::Assertions

# P = 2 ** 256 - 2 ** 32 - 977
P = 2 ** 256 - 2 ** 32 - 313441 # We all like hacks, ain't we?
O = [Float::INFINITY, Float::INFINITY]

def inv(n)
  n.pow(P - 2, P)
end

def sqrt(n)
  z = 1
  z += 1 while z.pow((P - 1) / 2, P) != P - 1
  q = P - 1
  m = 0
  while q % 2 == 0
    q /= 2
    m += 1
  end
  c = z.pow(q, P)
  t = n.pow(q, P)
  r = n.pow((q + 1) / 2, P)
  m.downto(2) do |i|
    tmp = t.pow(2 ** (i - 2), P)
    if tmp != 1
      r = r * c % P
      t = t * c ** 2 % P
    end
    c = c ** 2 % P
  end
  r
end

def add(a, b)
  return a if b == O
  return b if a == O
  if a[0] == b[0] && a[1] == b[1]
    l = (3 * a[0] ** 2) * inv(2 * a[1])
    x = l ** 2 - 2 * a[0]
  else
    return O if b[0] == a[0]
    l = (b[1] - a[1]) * inv(b[0] - a[0])
    x = l ** 2 - a[0] - b[0]
  end
  [x % P, (l * (a[0] - x) - a[1]) % P]
end

def mul(a, n)
  k = O
  while n != 0
    if n % 2 == 1
      k = add(k, a)
    end
    a = add(a, a)
    n /= 2
  end
  k
end

Gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
Gy = sqrt(Gx ** 3 + 7)
G = [Gx, Gy]

h = [
  0x56df2adff3c3749cc4c62c9e7da339dc02d157868a1d76f9d058d634d6a9525f,
  0xc167d7eb600437e2d6ead69ebcf2b1b2f88939c0fafda0b19aa3db33f5024b43,
]

###################################################

mod = P+1
factors = [2**4, 3, 23, 251, 157229, 7392373, 8666891, 18222037, 696663547, 946050631, 237140208281, 291304131568817]
ord = factors.inject(&:*)

gpq = ['a = Mod(0,1)']
factors.each do |f|
  t = ord / f
  x = nil

  puts "\033[32m[*] %s\033[0m" % ['calculating index mod %d ...' % f]
  IO.popen("./solver", "r+") do |io|
    io.puts P, Gx, Gy, h[0], h[1], f, t
    x, _ = io.read.scan(/Mod\((.*?), (.*?)\)/).flatten.map(&:to_i)
  end
  puts "\033[36m=> %s\033[0m" % [x]
  puts

  gpq << 'a = chinese(a, Mod(%d, %d))' % [x, f]
end

x, m = 0, 0
IO.popen("gp -q", "r+") do |io|
  io.puts gpq
  io.close_write
  x, m = io.read.lines[-1].scan(/Mod\((.*?), (.*?)\)/).flatten.map(&:to_i)
end

puts "\033[33m%s\033[0m" % ["index mod %d = %d" % [m, x]]
gets

puts 'FLAG candidates:'
50.times do |i|
  puts [(x + i*m).to_s(16)].pack("H*").inspect.gsub("TSGCTF", "\033[97;41mTSGCTF\033[0m")
end
