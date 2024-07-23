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
