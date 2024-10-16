puts 'hello'
puts Ractor.current

a = Ractor.new do
  p Ractor.current
end

a.take
