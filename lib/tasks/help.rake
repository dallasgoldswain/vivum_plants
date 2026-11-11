namespace :help do
  desc "Mark a help topic reviewed (D77): bin/rails \"help:review[topic-id]\""
  task :review, [ :id ] => :environment do |_task, args|
    abort "Usage: bin/rails \"help:review[topic-id]\"" if args[:id].blank?

    topic = HelpTopic.find(args[:id])
    topic.review!
    puts "Reviewed #{topic.id} on #{Date.current.iso8601}. Editing its text later needs a new review."
  end

  desc "List help topics with their review state and the capabilities they cover"
  task status: :environment do
    HelpTopic.all.each do |topic|
      state = topic.reviewed? ? "reviewed #{topic.reviewed}" : (topic.reviewed ? "changed since review" : "not reviewed")
      puts "#{topic.id.ljust(24)} #{state.ljust(22)} #{topic.capabilities.join(', ')}"
    end
  end

  desc "Regenerate help screenshots with headless Chrome (D78)"
  task :screenshots do
    sh "bin/rails test test/system/help"
  end
end
