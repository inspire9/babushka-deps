dep 'existing db', :username, :db_name do
  setup {
    requires "existing #{var(:db, :default => 'postgres')} db".with(username, db_name)
  }
end

dep 'db gem' do
  setup {
    define_var :db, :choices => %w[postgres mysql]
    requires var(:db) == 'postgres' ? 'pg.gem' : "#{var(:db)}.gem"
  }
end

dep 'deployed migrations run', :old_id, :new_id, :env do
  requires_when_unmet 'maintenance page up'
  requires_when_unmet 'migrated db'.with(shell('whoami'), '.', env)
  met? {
    if @run
      true # done
    else
      # If the branch was changed, git supplies 0000000 for old_id,
      # so the commit range is 'everything'.
      effective_old_id = old_id[/^0+$/] ? '' : old_id
      pending = shell("git diff --numstat #{effective_old_id}..#{new_id}").split("\n").grep(/^[\d\s]+db\/migrate\//)
      if pending.empty?
        log "No new migrations."
        true
      else
        log "#{pending.length} migration#{'s' unless pending.length == 1} to run:"
        pending.each {|p| log p }
        false
      end
    end
  }
  meet {
    @run = true
  }
end
