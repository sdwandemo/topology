%w(yaml pathname fileutils).each(&method(:require))

cmd = "docker run -dti -v /mnt/images:/mnt/images -v /opt/tmp:/opt/tmp sdwandemo/tiny-helper"
uri = "https://raw.githubusercontent.com/sdwandemo/topology/master/docker-compose.yml"
compose_file = YAML.load(open(uri).read)
images = compose_file['services'].select{|k,v| v['environment'] && v['environment']['VM_DISK']}

src_dst = images.map{|k,v|  "/opt/tmp/#{Pathname.new(v['environment']['VM_DISK']).basename.to_s} /mnt/images/_#{Pathname.new(v['environment']['VM_DISK']).basename.to_s.gsub('.qcow2', '')}-#{k}.qcow2"}
sc = ['#!/bin/bash']
src_dst.each { |i| sc << "#{cmd} cp #{i} && touch #{i.split(' ').last}.lock" }
Pathname.new('/opt/tmp/init_images').write(sc.join("\n"))
FileUtils.chmod(0755, '/opt/tmp/init_images')
