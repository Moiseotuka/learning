import {
  Atom,
  Bot,
  BrainCircuit,
  CircuitBoard,
  Cloud,
  Cpu,
  Database,
  LayoutDashboard,
  Network,
  ShieldCheck,
  Terminal,
  type LucideIcon,
} from "lucide-react";

const iconMap: Record<string, LucideIcon> = {
  terminal: Terminal,
  layout: LayoutDashboard,
  brain: BrainCircuit,
  shield: ShieldCheck,
  network: Network,
  cpu: Cpu,
  circuit: CircuitBoard,
  atom: Atom,
  robot: Bot,
  cloud: Cloud,
  database: Database,
};

export function CategoryIcon({ name, className }: { name: string; className?: string }) {
  const Icon = iconMap[name] ?? Terminal;
  return <Icon className={className} aria-hidden />;
}
