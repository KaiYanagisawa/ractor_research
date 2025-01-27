r = Ractor.new do
  Ractor.yield 'ok'
end

p r.take
