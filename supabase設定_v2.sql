-- ============================================================
-- 販賣部 / 泳裝部 日結與盤點系統  資料庫結構 v2
-- 用法:Supabase 後台 → SQL Editor → New query → 貼上全部 → Run
-- 可重複執行(會先清掉舊的同名表再建立)
-- ============================================================

-- ---------- 商品主檔 ----------
create table if not exists public.products (
  id           bigint generated always as identity primary key,
  code         text not null,                       -- 商品代號
  name         text not null,                       -- 商品名稱
  dept         text not null,                       -- 部門:販賣部 / 泳裝部
  category     text default '',                     -- 分類
  price        numeric not null default 0,          -- 單價
  member_price numeric default null,                -- 會員價
  staff_price  numeric default null,                -- 員工價
  track_stock  boolean not null default true,       -- 是否計庫存
  active       boolean not null default true,       -- 是否啟用
  note         text default '',                     -- 備註
  stock        numeric not null default 0,          -- 目前庫存(=明日原本庫存)
  sort         int default 0,                       -- 排序
  updated_at   timestamptz not null default now(),
  unique (dept, code)
);

-- ---------- 日結表 ----------
create table if not exists public.daily_entries (
  id            bigint generated always as identity primary key,
  date          date not null,
  dept          text not null,
  product_code  text not null,
  product_name  text not null,
  open_stock    numeric not null default 0,   -- 原本庫存
  purchase      numeric not null default 0,   -- 進貨
  return_qty    numeric not null default 0,   -- 退貨
  sold          numeric not null default 0,   -- 銷售數量
  staff_buy     numeric not null default 0,   -- 員購數量
  treat         numeric not null default 0,   -- 招待數量
  price         numeric not null default 0,   -- 單價
  subtotal      numeric not null default 0,   -- 銷售小計 = sold * price
  close_stock   numeric not null default 0,   -- 結算後庫存
  note          text default '',
  created_at    timestamptz not null default now()
);
create index if not exists idx_daily_date_dept on public.daily_entries(date, dept);

-- ---------- 盤點表 ----------
create table if not exists public.stocktakes (
  id            bigint generated always as identity primary key,
  date          date not null,
  dept          text not null,
  product_code  text not null,
  product_name  text not null,
  system_stock  numeric not null default 0,  -- 系統結算後庫存
  actual_stock  numeric not null default 0,  -- 實際盤點數量
  diff          numeric not null default 0,  -- 差異 = 實際 - 系統
  status        text default '',             -- 正確 / 短少 / 多出 / 需主管確認
  note          text default '',
  created_at    timestamptz not null default now()
);
create index if not exists idx_stk_date_dept on public.stocktakes(date, dept);

-- ============================================================
-- 權限:開啟 RLS,允許匿名(anon)讀寫(內部工具用)
-- ============================================================
alter table public.products      enable row level security;
alter table public.daily_entries enable row level security;
alter table public.stocktakes    enable row level security;

-- 先移除可能存在的同名政策,避免重複執行報錯
drop policy if exists p_products_all on public.products;
drop policy if exists p_daily_all    on public.daily_entries;
drop policy if exists p_stk_all      on public.stocktakes;

create policy p_products_all on public.products
  for all to anon using (true) with check (true);
create policy p_daily_all on public.daily_entries
  for all to anon using (true) with check (true);
create policy p_stk_all on public.stocktakes
  for all to anon using (true) with check (true);

grant usage on schema public to anon;
grant all on public.products, public.daily_entries, public.stocktakes to anon;
grant usage, select on all sequences in schema public to anon;
