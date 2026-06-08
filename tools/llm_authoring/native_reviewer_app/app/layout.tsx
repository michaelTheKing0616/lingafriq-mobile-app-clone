import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "LingAfriq Native Reviewer",
  description: "Native-speaker review queue for curriculum and game content",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header className="site-header">
          <a href="/" className="brand">
            LingAfriq · Native Review
          </a>
        </header>
        <main className="site-main">{children}</main>
      </body>
    </html>
  );
}
