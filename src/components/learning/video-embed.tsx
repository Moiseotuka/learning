import { VideoOffIcon } from "lucide-react";

import { messages } from "@/i18n";
import { extractYouTubeId, toEmbedUrl } from "@/lib/embed-url";
import { cn } from "cn";
import { YouTubePlayer } from "@/components/learning/youtube-player";

const t = messages.learner;

export function VideoEmbed({
  url,
  title,
}: {
  url: string | null;
  title: string;
}) {
  const embed = url ? toEmbedUrl(url) : null;
  const videoId = url ? extractYouTubeId(url) : null;
  const isDirectFile = url ? /\.(mp4|webm|ogg|ogv)(\?.*)?$/i.test(url) : false;

  return (
    <div className="relative aspect-video w-full overflow-hidden rounded-2xl border border-hairline bg-muted/40">
      {isDirectFile && url ? (
        <video
          src={url}
          controls
          playsInline
          className="absolute inset-0 size-full bg-black"
        />
      ) : videoId ? (
        <YouTubePlayer videoId={videoId} title={title} />
      ) : embed ? (
        <iframe
          src={embed}
          title={title}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
          loading="lazy"
          className="absolute inset-0 size-full"
        />
      ) : (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 px-6 text-center">
          <VideoOffIcon className="size-6 text-muted-foreground" aria-hidden />
          <p className="max-w-sm text-sm leading-relaxed text-muted-foreground">
            {t.videoMissing}
          </p>
        </div>
      )}
    </div>
  );
}

function renderInline(text: string) {
  return text.split(/(`[^`]+`)/g).map((part, index) =>
    part.length > 2 && part.startsWith("`") && part.endsWith("`") ? (
      <code
        key={index}
        className="rounded bg-muted px-1.5 py-0.5 font-mono text-[15px] text-foreground"
      >
        {part.slice(1, -1)}
      </code>
    ) : (
      <span key={index}>{part}</span>
    ),
  );
}

/** Découpe en blocs séparés par une ligne vide, sans couper dans un ``` . */
function splitLessonBlocks(content: string): string[] {
  const blocks: string[] = [];
  let current: string[] = [];
  let inFence = false;
  for (const line of content.split("\n")) {
    if (line.trimStart().startsWith("```")) inFence = !inFence;
    if (!inFence && line.trim() === "") {
      if (current.length > 0) {
        blocks.push(current.join("\n").trim());
        current = [];
      }
      continue;
    }
    current.push(line);
  }
  if (current.length > 0) blocks.push(current.join("\n").trim());
  return blocks.filter(Boolean);
}

/** Corps d'un bloc ```lang : retire la ligne d'en-tête et le ``` final. */
function fenceBody(block: string): string {
  const firstBreak = block.indexOf("\n");
  let body = firstBreak >= 0 ? block.slice(firstBreak + 1) : "";
  if (body.endsWith("```")) body = body.slice(0, -3);
  return body.replace(/^\n+|\n+$/g, "");
}

/** Bloc ```table : 1re ligne = en-tête, séparateur --- | --- facultatif. */
function TableBlock({ block }: { block: string }) {
  const rows = fenceBody(block)
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
  const isSeparator = (line: string) =>
    /^[\s\-:|]+$/.test(line) && line.includes("-");
  const cellsOf = (line: string) => {
    const parts = line.split("|").map((cell) => cell.trim());
    if (line.startsWith("|")) parts.shift();
    if (line.endsWith("|")) parts.pop();
    return parts;
  };
  const header = cellsOf(rows[0] ?? "");
  const bodyRows = rows.slice(1).filter((line) => !isSeparator(line));

  return (
    <div className="overflow-x-auto rounded-xl border border-hairline">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-hairline bg-muted/50">
            {header.map((cell, cellIndex) => (
              <th
                key={cellIndex}
                className="px-3 py-2 text-left font-semibold text-foreground"
              >
                {renderInline(cell)}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {bodyRows.map((line, rowIndex) => (
            <tr key={rowIndex} className="border-b border-hairline last:border-b-0">
              {cellsOf(line).map((cell, cellIndex) => (
                <td
                  key={cellIndex}
                  className="px-3 py-2 align-top text-foreground/85"
                >
                  {renderInline(cell.trim())}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

/** Bloc ```image : première ligne « URL », séparateur | puis légende. */
function ImageBlock({ block }: { block: string }) {
  const body = fenceBody(block);
  const [rawUrl, rawAlt] = body.split("|");
  const url = (rawUrl ?? "").trim();
  const alt = (rawAlt ?? "").trim();

  if (!/^https?:\/\//.test(url)) {
    return (
      <p className="text-sm text-muted-foreground">
        Image indisponible : {url || "URL absente"}
      </p>
    );
  }

  return (
    <figure>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={url}
        alt={alt}
        loading="lazy"
        className="w-full rounded-xl border border-hairline bg-muted/30"
      />
      {alt ? (
        <figcaption className="mt-2 text-sm text-muted-foreground">
          {alt}
        </figcaption>
      ) : null}
    </figure>
  );
}

export function LessonBody({
  content,
  className,
}: {
  content: string;
  className?: string;
}) {
  const blocks = splitLessonBlocks(content);

  return (
    <div className={cn("max-w-[72ch] space-y-6", className)}>
      {blocks.map((block, index) => {
        const lines = block.split("\n").map((line) => line.trim());
        const heading = block.match(/^(#{2,4})\s+(.*)$/);

        if (heading) {
          return (
            <h3
              key={index}
              className="text-xl font-semibold text-foreground"
            >
              {renderInline(heading[2])}
            </h3>
          );
        }

        if (block.startsWith("```table")) {
          return <TableBlock key={index} block={block} />;
        }

        if (block.startsWith("```image")) {
          return <ImageBlock key={index} block={block} />;
        }

        if (block.startsWith("```")) {
          const code = block
            .replace(/^```[^\n]*\n?/, "")
            .replace(/\n?```$/, "");
          return (
            <pre
              key={index}
              className="overflow-x-auto rounded-lg border border-hairline bg-muted/60 p-4 font-mono text-[14px] leading-6 text-foreground"
            >
              <code>{code}</code>
            </pre>
          );
        }

        if (lines.every((line) => line.startsWith("- "))) {
          return (
            <ul key={index} className="space-y-2">
              {lines.map((line) => (
                <li
                  key={line}
                  className="flex gap-2.5 text-[17px] leading-8 text-foreground/85"
                >
                  <span className="mt-3.5 size-1.5 shrink-0 rounded-full bg-electric" />
                  <span>{renderInline(line.slice(2))}</span>
                </li>
              ))}
            </ul>
          );
        }

        if (lines.every((line) => /^\d+\.\s+/.test(line))) {
          return (
            <ol key={index} className="list-decimal space-y-2 pl-5">
              {lines.map((line) => (
                <li
                  key={line}
                  className="text-[17px] leading-8 text-foreground/85 marker:text-muted-foreground"
                >
                  {renderInline(line.replace(/^\d+\.\s+/, ""))}
                </li>
              ))}
            </ol>
          );
        }

        return (
          <p
            key={index}
            className="text-[17px] leading-8 text-foreground/85"
          >
            {renderInline(block)}
          </p>
        );
      })}
    </div>
  );
}
