require 'benchmark'

def bubble_sort(array)
  size = array.size

  (size - 1).times do
    (size - 1).times do |j|
      array[j], array[j + 1] = array[j + 1], array[j] if array[j] > array[j + 1]
    end
  end
end

def bubble_sort_parallel(array)
  start_div = Time.now

  # divide using pivot(MAX/2)
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

  p "divide: #{Time.now - start_div}"

  p "branch_point = #{branch_point}"

  # parallel bubble sort
  Ractor.make_shareable(array)

  start_r1 = Time.now
  r1 = Ractor.new do
    start_rec1 = Time.now
    smaller_part = Ractor.receive
    p "r1_rec: #{Time.now - start_rec1}"

    start_bubble1 = Time.now
    bubble_sort(smaller_part)
    p "bubble1: #{Time.now - start_bubble1}"

    smaller_part
  end
  p "r1_new: #{Time.now - start_r1}"

  start_r2 = Time.now
  r2 = Ractor.new do
    start_rec2 = Time.now
    larger_part = Ractor.receive
    p "r2_rec: #{Time.now - start_rec2}"

    start_bubble2 = Time.now
    bubble_sort(larger_part)
    p "bubble2: #{Time.now - start_bubble2}"

    larger_part
  end
  p "r2_new: #{Time.now - start_r2}"

  start_send = Time.now
  r1.send(array[...branch_point])
  p "start_send: #{Time.now - start_send}"

  start_send2 = Time.now
  r2.send(array[branch_point..])
  p "start_send2: #{Time.now - start_send2}"

  start_r1take = Time.now
  smaller_part = r1.take
  p "r1_take: #{Time.now - start_r1take}"

  start_r2take = Time.now
  larger_part = r2.take
  p "r2_take: #{Time.now - start_r2take}"

  start_concat = Time.now
  sorted = smaller_part.concat(larger_part)
  p "concat: #{Time.now - start_concat}"

  sorted
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
