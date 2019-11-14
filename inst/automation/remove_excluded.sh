#!/bin/bash
ruby -e 'require "json"; dirs = Dir["*/"].map{|z| z.sub(/\//, "")}; ex = File.read("/home/ubuntu/exclude_list.txt").split; dirs.each { |z| %x[rm -rf #{z}] if File.directory?(z) && ex.include?(z)}'
