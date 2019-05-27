local BackupHelper = {
  backups = {}
}
module = BackupHelper

function BackupHelper.backup(copy)
  table.insert(BackupHelper.backups, copy)
end

function BackupHelper.peek()
    return BackupHelper.backups[#BackupHelper.backups]
end

function BackupHelper.pop()
    local backup = BackupHelper.peek()
    if backup then
      table.remove(BackupHelper.backups, #BackupHelper.backups)
    end
    return backup
end
