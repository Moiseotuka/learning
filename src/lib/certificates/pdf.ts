import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { PDFDocument, StandardFonts, rgb, type PDFFont } from "pdf-lib";
import QRCode from "qrcode";

const PAGE_W = 1232;
const PAGE_H = 864;
const CENTER_X = 618;

const CREAM_NOM = rgb(0.9412, 0.9451, 0.9294);
const CREAM_TITRE = rgb(0.9412, 0.9412, 0.9255);
const CREAM_NUMERO = rgb(0.9333, 0.9216, 0.8824);
const CREAM_QR = rgb(0.9373, 0.9294, 0.9098);
const NAVY = rgb(0.13, 0.19, 0.31);
const NUMBER_COLOR = rgb(0.35, 0.35, 0.33);

export type CertificatePdfData = {
  code: string;
  title: string;
  full_name: string;
};

function fitSize(
  font: PDFFont,
  text: string,
  maxSize: number,
  maxWidth: number,
): number {
  let size = maxSize;
  while (size > 10 && font.widthOfTextAtSize(text, size) > maxWidth) {
    size -= 1;
  }
  return size;
}

export async function renderCertificatePdf(
  data: CertificatePdfData,
): Promise<Uint8Array> {
  const cleanPath = path.join(process.cwd(), "public", "certificat-clean.jpg");
  const fallbackPath = path.join(process.cwd(), "public", "certificat.jpg");
  const clean = existsSync(cleanPath);
  const imageBytes = readFileSync(clean ? cleanPath : fallbackPath);

  const doc = await PDFDocument.create();
  const image = await doc.embedJpg(imageBytes);
  const page = doc.addPage([PAGE_W, PAGE_H]);
  page.drawImage(image, { x: 0, y: 0, width: PAGE_W, height: PAGE_H });

  const regular = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const oblique = await doc.embedFont(StandardFonts.HelveticaOblique);

  if (!clean) {
    page.drawRectangle({
      x: 245,
      y: PAGE_H - 438,
      width: 745,
      height: 116,
      color: CREAM_NOM,
    });
    page.drawRectangle({
      x: 330,
      y: PAGE_H - 534,
      width: 580,
      height: 62,
      color: CREAM_TITRE,
    });
    page.drawRectangle({
      x: 890,
      y: PAGE_H - 752,
      width: 155,
      height: 32,
      color: CREAM_NUMERO,
    });
    page.drawRectangle({
      x: 175,
      y: PAGE_H - 748,
      width: 82,
      height: 83,
      color: CREAM_QR,
    });
  }

  const name = data.full_name;
  const nameSize = fitSize(oblique, name, 62, 650);
  const nameWidth = oblique.widthOfTextAtSize(name, nameSize);
  page.drawText(name, {
    x: CENTER_X - nameWidth / 2,
    y: PAGE_H - 405,
    size: nameSize,
    font: oblique,
    color: NAVY,
  });

  const title = data.title;
  const titleSize = fitSize(bold, title, 34, 505);
  const titleWidth = bold.widthOfTextAtSize(title, titleSize);
  page.drawText(title, {
    x: CENTER_X - titleWidth / 2,
    y: PAGE_H - 517,
    size: titleSize,
    font: bold,
    color: NAVY,
  });

  page.drawText(data.code, {
    x: 900,
    y: PAGE_H - 747,
    size: 16,
    font: regular,
    color: NUMBER_COLOR,
  });

  const base = (process.env.NEXT_PUBLIC_SITE_URL && !/localhost|127\.0\.0\.1|0\.0\.0\.0/i.test(process.env.NEXT_PUBLIC_SITE_URL)
    ? process.env.NEXT_PUBLIC_SITE_URL
    : (process.env.VERCEL_PROJECT_PRODUCTION_URL ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}` : "https://elearning-three-phi.vercel.app"));
  const qrUrl = `${base}/verifier?code=${encodeURIComponent(data.code)}`;
  const qrPng = await QRCode.toBuffer(qrUrl, {
    type: "png",
    width: 140,
    margin: 1,
  });
  const qr = await doc.embedPng(qrPng);
  page.drawImage(qr, { x: 181, y: PAGE_H - 741, width: 70, height: 70 });

  return doc.save();
}
