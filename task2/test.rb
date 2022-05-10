counts = Hash.new(0)
1000.times do
  output = `curl -s -H "Host: homework.epam" http://192.168.64.2 | grep 'pod namespace'`
  counts[output.strip.split.last] += 1
end
puts counts