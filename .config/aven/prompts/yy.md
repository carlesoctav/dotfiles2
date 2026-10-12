please work on this task {{task_ref}}.

aven awareness (required): aven is this workspace's local task manager.
- Run 'aven prime' for agent guidance plus live work, and 'aven context {{task_ref}}' for this task.
- Mark the task active: aven edit {{task_ref}} --status active
- Leave handoff context when done or blocked with: aven note {{task_ref}} --stdin (append-style notes), starting your note with [agent]
- Never commit unless specified by the user.
