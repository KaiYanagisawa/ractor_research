def slow_task(id)
  sleep(2)
  "Task #{id} Complete"
end

ractors = []
5.times do |i|
  ractors << Ractor.new(i) do |id|
    slow_task(id)
  end
end

results = ractors.map(&:take)
puts results

r1 = Ractor.new do
  sleep(2)
  p 'I am in Ractor'
end
r2 = Ractor.new do
  p 'I am in Ractor2'
end

r1.take
r2.take
