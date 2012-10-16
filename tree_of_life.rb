require 'nokogiri'

doc = Nokogiri::XML(File.read('data.xml'))

puts `mkdir repo`

#copy files to repo folder, so they will pushed to root branch
files_to_commit = %w(data.xml tree_of_life.rb README.md)
files_to_commit.each do |f|
  puts `cp #{f} repo/`
end

Dir.chdir('repo') do

  #initialize git repository
  puts `git init`
  puts `git add .`
  puts `git commit -am "root"`
  puts `git checkout -b root`
  puts `git branch -D master`
  puts `git remote add origin git@github.com:benben/tree-of-life.git`
  puts `git push origin root`

  @species = []
  c = 0

  #create an array from clades in data.xml
  doc.search('phylogeny clade').each do |clade_node|
    if clade_node.parent.search('> name').first
      @species[c] = []
      @species[c] << clade_node.search(' > name').first.content
      @species[c] << clade_node.parent.search('> name').first.content
    end
    c += 1
  end

  @already_created_branches = []

  @species.compact.each do |s|
    current_branch = s[0].gsub(' ', '_')
    parent_branch  = s[1].gsub(' ', '_')

    #create or checkout parent branch
    if @already_created_branches.include?(parent_branch)
      puts `git checkout '#{parent_branch}'`
    else
      puts `git checkout -b '#{parent_branch}'`
      @already_created_branches << parent_branch
    end

    #create or checkout current branch
    if @already_created_branches.include?(current_branch)
      puts `git checkout '#{current_branch}'`
    else
      puts `git checkout -b '#{current_branch}'`
      @already_created_branches << current_branch
    end

    # delete root files
    if s[1] == 'root'
      files_to_commit.each do |f|
        puts `git rm #{f}`
      end
    end

    #delete other files
    puts `git rm *`
    #add a dummy file
    puts `echo "#{s[0]}" > #{current_branch}`
    puts `git add .`
    puts `git commit -am "#{s[0]}"`
  end

  puts `git push -f --all origin`
end
