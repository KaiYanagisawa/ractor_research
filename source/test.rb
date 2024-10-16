time = Time.now
r1 = Ractor.new do
  start = Time.now
  a = Ractor.receive
  c = a.map { |n| n + 1 }
  # sleep 5
  p c[2..10]
  p "r1: #{Time.now - start}"
end

r2 = Ractor.new do
  start = Time.now
  b = Ractor.receive
  # c = b.map { |n| n - 1 }
  c = b
  # sleep 5
  p c[2..10]
  p "r2: #{Time.now - start}"
end

a = Array.new(10_000_000) { |i| i }
b = a

r1.send(a)
r2.send(b)

r1.take
r2.take

p "end: #{Time.now - time}"
