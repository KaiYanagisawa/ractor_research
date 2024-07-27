require 'benchmark'

def bubble_sort(array)
  start = Time.now
  size = array.size

  (size - 1).times do
    (size - 1).times do |j|
      array[j], array[j + 1] = array[j + 1], array[j] if array[j] > array[j + 1]
    end
  end

  p "sort: #{Time.now - start}"

  array
end

def bubble_sort_parallel(array)
  # divide using pivot(MAX/2)
  start_divide = Time.now

  from_first = 0
  from_last = NUM - 1

  while from_first < from_last
    from_first += 1 while array[from_first] < MAX / 2
    from_last -= 1 while array[from_last] >= MAX / 2

    next unless from_first < from_last

    array_from_first = array[from_first]
    array[from_first] = array[from_last]
    array[from_last] = array_from_first
  end

  branch_point = from_first

  from_first2 = 0
  from_last2 = branch_point

  while from_first2 < from_last2
    from_first2 += 1 while array[from_first2] < MAX / 4
    from_last2 -= 1 while array[from_last2] >= MAX / 4

    next unless from_first2 < from_last2

    array_from_first = array[from_first2]
    array[from_first2] = array[from_last2]
    array[from_last2] = array_from_first
  end

  branch_point2 = from_first2

  from_first3 = branch_point
  from_last3 = NUM - 1

  while from_first3 < from_last3
    from_first3 += 1 while array[from_first3] < MAX * 3 / 4
    from_last3 -= 1 while array[from_last3] >= MAX * 3 / 4

    next unless from_first3 < from_last3

    array_from_first = array[from_first3]
    array[from_first3] = array[from_last3]
    array[from_last3] = array_from_first
  end

  branch_point3 = from_first3

  p "divide: #{Time.now - start_divide}"

  p branch_point2
  p branch_point
  p branch_point3

  # parallel bubble sort
  Ractor.make_shareable(array)

  new_r1 = Time.now
  r1 = Ractor.new do
    smaller_part = Ractor.receive

    start = Time.now
    bubble_sort(smaller_part)
    p "r1_sort: #{Time.now - start}"

    smaller_part
  end
  p "new_r1: #{Time.now - new_r1}"

  new_r2 = Time.now
  r2 = Ractor.new do
    larger_part = Ractor.receive

    start = Time.now
    bubble_sort(larger_part)
    p "r2_sort: #{Time.now - start}"

    larger_part
  end
  p "new_r2: #{Time.now - new_r2}"

  new_r3 = Time.now
  r3 = Ractor.new do
    larger_part = Ractor.receive

    start = Time.now
    bubble_sort(larger_part)
    p "r3_sort: #{Time.now - start}"

    larger_part
  end
  p "new_r3: #{Time.now - new_r3}"

  new_r4 = Time.now
  r4 = Ractor.new do
    larger_part = Ractor.receive

    start = Time.now
    bubble_sort(larger_part)
    p "r4_sort: #{Time.now - start}"

    larger_part
  end
  p "new_r4: #{Time.now - new_r4}"

  r1.send(array[...branch_point2])
  r2.send(array[branch_point2...branch_point])
  r3.send(array[branch_point...branch_point3])
  r4.send(array[branch_point3..])

  part1 = r1.take
  part2 = r2.take
  part3 = r3.take
  part4 = r4.take

  # smaller_part.concat(larger_part)
  part1.concat(part2).concat(part3).concat(part4)
end

def print_array(array, max_display = 10)
  n = array.size
  n.times do |i|
    if i < max_display
      print "#{array[i].to_s.rjust(5)}#{(i + 1) % 15 == 0 ? "\n" : ' '}"
    elsif i == max_display
      puts "\n      ********"
    end

    if i >= n - max_display
      print "#{array[i].to_s.rjust(5)}#{(i + 1) % 15 == 0 ? "\n" : ' '}"
    end
  end
  puts "\n"
end

raise 'Usage: ruby script.rb MAX NUM' if ARGV.size != 2

MAX = ARGV[0].to_i
NUM = ARGV[1].to_i

data = Array.new(NUM) { rand(MAX) }

puts '----- Before sort -----'
print_array(data)

time = Benchmark.realtime do
  data = bubble_sort_parallel(data)
end

puts "\n----- After Sort --#{time}sec---"
print_array(data)
