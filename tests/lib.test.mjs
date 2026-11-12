// Test delle funzioni pure. Esegui con: node --test tests/*.test.mjs
import test from "node:test";
import assert from "node:assert/strict";

import { registrableDomain, domainFromUrl } from "../extension/lib/domains.js";
import { buildModel } from "../extension/lib/scan.js";
import { buildRequest } from "../extension/lib/gdpr.js";

test("registrableDomain", () => {
  assert.equal(registrableDomain(".google.com"), "google.com");
  assert.equal(registrableDomain("a.b.example.co.uk"), "example.co.uk");
  assert.equal(registrableDomain("localhost"), "localhost");
  assert.equal(registrableDomain("192.168.1.10"), "192.168.1.10");
  assert.equal(registrableDomain(""), "");
});

test("domainFromUrl ignora URL non http(s)", () => {
  assert.equal(domainFromUrl("https://www.ansa.it/notizie"), "ansa.it");
  assert.equal(domainFromUrl("chrome://settings"), "");
  assert.equal(domainFromUrl("non un url"), "");
});

test("buildModel raggruppa e mette i tracker per primi", () => {
  const cookies = [
    { domain: ".ansa.it", name: "a" },
    { domain: ".ansa.it", name: "b" },
    { domain: "ads.criteo.com", name: "uid" },
  ];
  const history = [{ url: "https://www.ansa.it/x", visitCount: 3 }];
  const m = buildModel(cookies, history);
  assert.equal(m[0].domain, "criteo.com");
  assert.equal(m[0].tracker, true);
  assert.equal(m[0].company, "Criteo");
  assert.equal(m[1].domain, "ansa.it");
  assert.equal(m[1].cookies.length, 2);
  assert.equal(m[1].visits, 3);
});

test("buildRequest: usa solo nomi cookie, segnaposto se mancano nome/email", () => {
  const { subject, body } = buildRequest({
    domain: "criteo.com",
    company: "Criteo",
    cookieNames: ["uid", "uid", "cto_bundle"],
    lang: "it",
  });
  assert.match(subject, /Criteo/);
  assert.match(body, /uid, cto_bundle/);
  assert.match(body, /\[NOME E COGNOME\]/);
  assert.match(body, /art\. 17/);
});

test("buildRequest in inglese", () => {
  const { body } = buildRequest({ domain: "x.com", lang: "en", name: "Jane", email: "j@e.com" });
  assert.match(body, /Art\. 7\(3\)/);
  assert.match(body, /j@e\.com/);
});
