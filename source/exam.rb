def slow_task
  sleep(2)
  'Task Complete'
end

ractors = []
5.times do
  ractors << Ractor.new do
    slow_task
  end
end

results = ractors.map(&:take)
puts results
