# r = Ractor.new { raise "Error" }
# r.take # Warning: Exception raised in Ractor but not properly handled.

s = "hello"
a = 'test'
r = Ractor.new do
  s << "world"
end
p a

s << "ko1"
p r.take
