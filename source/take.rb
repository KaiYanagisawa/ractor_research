r = Ractor.new do
  sleep 10
  p 'a'
end

# r.take
