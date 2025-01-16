s = "hello"
r = Ractor.new do
  s << "world"
end

s << "ko1"
p r.take
