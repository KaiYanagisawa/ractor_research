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

  # parallel bubble sort
  Ractor.make_shareable(array)

  r1 = Ractor.new do
    smaller_part = Ractor.receive
    bubble_sort(smaller_part)
    smaller_part
  end

  r2 = Ractor.new do
    larger_part = Ractor.receive
    bubble_sort(larger_part)
    larger_part
  end

  r1.send(array[...branch_point])
  r2.send(array[branch_point..])

  smaller_part = r1.take
  larger_part = r2.take

  smaller_part.concat(larger_part)
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
