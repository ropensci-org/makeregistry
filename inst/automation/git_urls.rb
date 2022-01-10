#!/usr/bin/env ruby

require 'faraday'
require 'json'

puts "making new repository index file: packages.json"

def fetch_gh(org, page, per_page = 100)
  url = 'https://api.github.com/orgs/%s/repos' % org
  resp = Faraday.get(url) do |req|
    req.params['per_page'] = per_page
    req.params['page'] = page.to_s
    req.headers['Authorization'] = 'token ' + ENV['GITHUB_PAT']
    # req.headers['Authorization'] = 'token ' + ENV['GITHUB_PAT_SCOTT']
  end
  if !resp.success?
    raise "%s: %s" % [resp.status, resp.reason_phrase]
  end
  return resp
end

def gh_default_branch(owner_repo)
  url = 'https://api.github.com/repos/' + owner_repo
  resp = Faraday.get(url) do |req|
    req.headers['Authorization'] = 'token ' + ENV['GITHUB_PAT']
    # req.headers['Authorization'] = 'token ' + ENV['GITHUB_PAT_SCOTT']
  end
  if resp.success?
    return JSON.load(resp.body)["default_branch"] || "master"
  else
    return "master"
  end
end

# try reading exclude list, if fails or empty, or last pull failed due
# to a github error, then fail out
ff = File.read("inst/automation/exclude_list.txt");
if !ff.match?("ropensci_citations")
  raise "exclude_list.txt read failure"
end
ex = ff.split;

# ropensci
res_ropensci = []
(1..5).each do |x|
  res_ropensci << fetch_gh('ropensci', x)
end

# ropenscilabs
res_ropenscilabs = []
(1..3).each do |x|
  res_ropenscilabs << fetch_gh('ropenscilabs', x)
end

# parse JSON and flatten into an array
allres = [res_ropensci, res_ropenscilabs].flatten.map { |x| JSON.load(x.body) }.flatten;

# pull out name and git html (https) url
out = []
allres.each { |repo|
  out << {
    "package" => repo["name"],
    "url" => repo["html_url"],
    "branch" => repo["default_branch"]
  } unless repo["archived"] || repo["fork"] || ex.include?(repo["name"])
}

# add other repos (those repos not in ropensci or ropenscilabs)
nms = ["package", "url"]
nt_path = 'inst/automation/not_transferred.txt'
nt = File.read(nt_path).split
# others = resp.body.split("\n").map{ |z|
others = nt.map{ |z|
  vals = [z.split("/").last.sub(".git", ""), z]
  Hash[nms.zip(vals)]
}
# add default_branch
others.map { |e|
  if e["url"].match(/github/).nil?
    e["branch"] = "master"
  else
    e["branch"] = gh_default_branch(e["url"].gsub(/https:\/\/github.com\/|\.git/, ""))
  end
}
# combine
out.concat others

# write json file to disk
File.open('packages.json', 'w') do |f|
  f.puts(JSON.pretty_generate(out))
end
