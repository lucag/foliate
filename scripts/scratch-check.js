#!/usr/bin/env node
// Checks the local issue tracker under .scratch/ (see docs/agents/issue-tracker.md).
//   node scripts/scratch-check.js                  check every effort; exit 1 on problems
//   node scripts/scratch-check.js frontier <dir>   list the takeable tickets of one effort
import fs from 'node:fs'
import path from 'node:path'
import process from 'node:process'

const print = line => process.stdout.write(`${line}\n`)
const ROOT = path.resolve(import.meta.dirname, '..', '.scratch')
const STATUSES = new Set([
    'open', 'claimed', 'resolved', 'wontfix',
    'needs-triage', 'needs-info', 'ready-for-agent', 'ready-for-human',
])
const DONE = new Set(['resolved', 'wontfix'])
const TAKEABLE = new Set(['open', 'ready-for-agent', 'ready-for-human'])

const field = (text, name) => text.match(new RegExp(`^${name}: *(.*)$`, 'm'))?.[1].trim()

const loadEfforts = () => {
    const efforts = new Map()
    for (const dir of fs.readdirSync(ROOT).sort()) {
        const issuesDir = path.join(ROOT, dir, 'issues')
        if (!fs.existsSync(issuesDir)) continue
        const tickets = new Map()
        for (const file of fs.readdirSync(issuesDir).sort()) {
            const num = file.match(/^(\d{2})-.*\.md$/)?.[1]
            if (!num) continue
            const text = fs.readFileSync(path.join(issuesDir, file), 'utf8')
            tickets.set(num, {
                effort: dir, num, file,
                title: text.match(/^# (.*)$/m)?.[1] ?? file,
                type: field(text, 'Type'),
                status: field(text, 'Status'),
                blockedBy: field(text, 'Blocked by'),
            })
        }
        const mapFile = path.join(ROOT, dir, 'map.md')
        const map = fs.existsSync(mapFile) ? fs.readFileSync(mapFile, 'utf8') : null
        efforts.set(dir, { dir, tickets, map })
    }
    return efforts
}

// "01, macos-reader-milestone 07, 02 (if it runs)" → [{ effort, num, raw }]
const parseBlockers = (ticket, efforts, problems) => {
    const value = ticket.blockedBy
    if (!value || value === '(none)') return []
    return value.split(',').map(item => {
        const raw = item.replace(/\(.*?\)/g, '').trim()
        const m = raw.match(/^(?:([\w.-]+) )?(\d{2})$/)
        if (!m) {
            problems.push(`${ticket.effort}/${ticket.file}: unreadable blocker "${item.trim()}"`)
            return null
        }
        const effort = m[1] ?? ticket.effort
        const target = efforts.get(effort)?.tickets.get(m[2])
        if (!target) problems.push(`${ticket.effort}/${ticket.file}: blocker "${item.trim()}" not found`)
        return target ?? null
    }).filter(Boolean)
}

const section = (map, heading) => {
    const start = map.indexOf(`## ${heading}`)
    if (start < 0) return ''
    const next = map.indexOf('\n## ', start + 1)
    return map.slice(start, next < 0 ? undefined : next)
}

const check = efforts => {
    const problems = []
    for (const { dir, tickets, map } of efforts.values()) {
        for (const t of tickets.values()) {
            if (!STATUSES.has(t.status))
                problems.push(`${dir}/${t.file}: Status "${t.status ?? '(missing)'}" not in ${[...STATUSES].join('/')}`)
            parseBlockers(t, efforts, problems)
        }
        if (!map) continue
        const decisions = section(map, 'Decisions so far')
        const outOfScope = section(map, 'Out of scope')
        for (const t of tickets.values()) {
            const link = `issues/${t.file}`
            if (t.status === 'resolved' && !decisions.includes(link))
                problems.push(`${dir}/map.md: resolved ${t.file} has no Decisions-so-far line`)
            if (t.status === 'wontfix' && !outOfScope.includes(link))
                problems.push(`${dir}/map.md: wontfix ${t.file} has no Out-of-scope line`)
            if (t.status !== 'resolved' && decisions.includes(link))
                problems.push(`${dir}/map.md: Decisions so far links ${t.file}, which is ${t.status}`)
        }
    }
    return problems
}

const frontier = (efforts, dirArg) => {
    const dir = path.basename(path.resolve(dirArg))
    const effort = efforts.get(dir)
    if (!effort) throw new Error(`no effort "${dir}" under .scratch/`)
    const ignored = []
    return [...effort.tickets.values()].filter(t => TAKEABLE.has(t.status)
        && parseBlockers(t, efforts, ignored).every(b => DONE.has(b.status)))
}

const efforts = loadEfforts()
if (process.argv[2] === 'frontier') {
    const list = frontier(efforts, process.argv[3] ?? '.')
    for (const t of list) print(`${t.num}  ${t.status}${t.type ? ` (${t.type})` : ''}  ${t.title}`)
    if (!list.length) print('(frontier empty)')
} else {
    const problems = check(efforts)
    for (const p of problems) console.error(p)
    print(problems.length ? `${problems.length} problem(s)` : 'scratch: ok')
    process.exitCode = problems.length ? 1 : 0
}
