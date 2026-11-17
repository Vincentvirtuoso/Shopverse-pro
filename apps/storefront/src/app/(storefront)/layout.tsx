import { AppShell } from "@/components/layout/Appshell";

export default function StorefrontLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AppShell>{children}</AppShell>;
}
