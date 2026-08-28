export async function GET() {
  const uptime = process.uptime()
  const body = [
    '# HELP task_manager_process_uptime_seconds Process uptime in seconds.',
    '# TYPE task_manager_process_uptime_seconds gauge',
    `task_manager_process_uptime_seconds ${uptime}`,
  ].join('\n') + '\n'

  return new Response(body, {
    headers: {
      'Content-Type': 'text/plain; version=0.0.4; charset=utf-8',
    },
  })
}
