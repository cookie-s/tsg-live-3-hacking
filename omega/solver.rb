require_relative 'params'

UNITS = [[0,1],[0,-1],[1,0],[-1,0],[1,1],[-1,-1]]

def to_complex(x)
  a, b = x
  w = Math::E ** Complex(0, Math::PI*2.0/3.0)
  a + b*w
end

def add(x, y)
  a, b = x
  c, d = y
  [a+c, b+d]
end

def sub(x, y)
  a, b = x
  c, d = y
  [a-c, b-d]
end

def scalar(k)
  [k, 0]
end

def mul(*xs)
  r = [1, 0]
  xs.each do |x|
    a, b = r
    c, d = x
    r = [a*c - b*d, a*d + b*c - b*d]
  end
  r
end

def div(x, y)
  xc, yc = to_complex(x), to_complex(y)
  a, b = (xc / yc).rect
  [(a + b/Math.sqrt(3)).round, (b*2.0/Math.sqrt(3)).round]
end

def mod(x, y)
  100.times do
    k = div(x, y)
    x = sub(x, mul(k, y))
  end
  x
end

def norm(x)
  a, b = x
  a*a + b*b - a*b
end

modulos = MODULOS
res = PROBLEM

def extgcd(a, b)
  if b == [0, 0]
    case a
    when [1,0]
      {x: [1,0], y: [0,0], gcd: [1,0]}
    when [-1,0]
      {x: [-1,0], y: [0,0], gcd: [1,0]}
    when [0,1]
      {x: [-1,-1], y: [0,0], gcd: [1,0]}
    when [0,-1]
      {x: [1,1], y: [0,0], gcd: [1,0]}
    when [1,1]
      {x: [0,-1], y: [0,0], gcd: [1,0]}
    when [-1,-1]
      {x: [0,1], y: [0,0], gcd: [1,0]}
    else
      {x: [1,0], y: [0,0], gcd: a}
    end
  else
    k = div(a, b)
    prev = extgcd(b, sub(a, mul(k, b)))

    {
      x: prev[:y],
      y: sub(prev[:x], mul(k, prev[:y])),
      gcd: prev[:gcd]
    }
  end
end

def chinese(x1, m1, x2, m2)
  mt = extgcd(m1, m2)
  [add(mul(x1, m2, mt[:y]), mul(x2, m1, mt[:x])), mul(m1, m2)]
end

t, m = [[0,0], [1,0]]
res.each_with_index do |(tt, mm), i|
  puts 'x mod (%d + %dw) = %d + %dw' % [m[0], m[1], t[0], t[1]]
  t, m = chinese(tt, mm, t, m)
  t = mod(t, m)
  puts 'x mod (%d + %dw) = %d + %dw' % [mm[0], mm[1], tt[0], tt[1]]
  print '=>'
  if i <= 4
    gets
  else
    puts
  end
  puts 'x mod (%d + %dw) = %d + %dw' % [m[0], m[1], t[0], t[1]]
  if i <= 4
    gets
  else
    puts
  end
end

  puts "\033[97;41m%s\033[0m" % t.map{ |x| [x.to_s(16)].pack("H*")}.join
