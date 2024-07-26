require 'benchmark'

# GC.disable

def bubble_sort(array)
  size = array.size
  (size - 1).times do
    (size - 1).times do |j|
      array[j], array[j + 1] = array[j + 1], array[j] if array[j] > array[j + 1]
    end
  end
end

def one_ractor_bubble_sort(array)
  Ractor.make_shareable(array)

  r1 = Ractor.new do
    receive_array = Ractor.receive
    start = Time.now
    bubble_sort(receive_array)
    p "bubble_sort: #{Time.now - start}"
    receive_array
  end

  array_copy = array.dup

  r1.send(array_copy)

  r1.take
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

if ARGV.size != 2
  puts 'Usage: ruby script.rb MAX NUM'
  exit 1
end

MAX = ARGV[0].to_i
NUM = ARGV[1].to_i

data = Array.new(NUM) { rand(MAX) }

puts '----- Before sort -----'
print_array(data)

time = Benchmark.realtime do
  data = one_ractor_bubble_sort(data)
end

puts "\n----- After Sort --#{time}sec---"
print_array(data)

p "GC.count: #{GC.count}"
