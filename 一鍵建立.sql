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


-- 匯入 60 項商品(泳裝部 A碼 / 販賣部 B碼)
insert into public.products (code,name,dept,category,price,member_price,staff_price,track_stock,active,note,stock,sort) values
('A01','泳帽','泳裝部','',90,null,null,true,true,'',0,0),
('A04','胸墊','泳裝部','',50,null,null,true,true,'',0,1),
('A06','寶貝球(大+小)','泳裝部','',100,null,null,true,true,'',0,2),
('A07','防水尿布','泳裝部','',60,null,null,true,true,'',0,3),
('C01','無線耳塞','泳裝部','',70,null,null,true,true,'',0,4),
('C02','手臂圈','泳裝部','',280,null,null,true,true,'',0,5),
('C03','泳圈24吋','泳裝部','',290,null,null,true,true,'',0,6),
('C06','除霧劑','泳裝部','',200,null,null,true,true,'',0,7),
('C12','矽膠泳帽','泳裝部','',260,null,null,true,true,'',0,8),
('C15','耳塞','泳裝部','',80,null,null,true,true,'',0,9),
('C16','baby泳帽','泳裝部','',190,null,null,true,true,'',0,10),
('C21','兒童蛙鏡290','泳裝部','',290,null,null,true,true,'',0,11),
('C22','成人蛙鏡350','泳裝部','',350,null,null,true,true,'',0,12),
('C23','baby蛙鏡','泳裝部','',390,null,null,true,true,'',0,13),
('C24','近視蛙鏡','泳裝部','',490,null,null,true,true,'',0,14),
('C25','成人蛙鏡390','泳裝部','',390,null,null,true,true,'',0,15),
('E06','浮板 450','泳裝部','',450,null,null,true,true,'',0,16),
('E07','座船','泳裝部','',560,null,null,true,true,'',0,17),
('E08','可愛浮板','泳裝部','',390,null,null,true,true,'',0,18),
('A50','泳衣','泳裝部','',0,null,null,true,true,'',0,19),
('A51','泳褲','泳裝部','',0,null,null,true,true,'',0,20),
('D01','小毛巾','泳裝部','',80,null,null,true,true,'',0,21),
('D02','大毛巾','泳裝部','',300,null,null,true,true,'',0,22),
('D05','沐浴乳包','泳裝部','',35,null,null,true,true,'',0,23),
('D06','雨衣','泳裝部','',30,null,null,true,true,'',0,24),
('D07','玩具','泳裝部','',80,null,null,true,true,'',0,25),
('B01','寶礦力','販賣部','飲料',35,null,null,true,true,'',0,26),
('B02','汽水','販賣部','飲料',35,null,null,true,true,'',0,27),
('B03','分解茶','販賣部','飲料',40,null,null,true,true,'',0,28),
('B04','水','販賣部','飲料',25,null,null,true,true,'',0,29),
('B05','大麵','販賣部','食品',80,null,null,true,true,'',0,30),
('B06','中麵','販賣部','食品',65,null,null,true,true,'',0,31),
('B07','小麵','販賣部','食品',55,null,null,true,true,'',0,32),
('B08','餅乾','販賣部','食品',35,null,null,true,true,'',0,33),
('B09','波爾茶','販賣部','飲料',40,null,null,true,true,'',0,34),
('B10','客惟您','販賣部','飲料',25,null,null,true,true,'',0,35),
('B11','加水','販賣部','飲料',10,null,null,true,true,'',0,36),
('B12','水蠻牛','販賣部','飲料',40,null,null,true,true,'',0,37),
('B13','可爾必思','販賣部','飲料',25,null,null,true,true,'',0,38),
('B14','健酪','販賣部','飲料',35,null,null,true,true,'',0,39),
('B15','PIZZA','販賣部','食品',85,null,null,true,true,'',0,40),
('B16','寶礦力(加購)','販賣部','飲料',25,null,null,true,true,'披薩加購價',0,41),
('B17','汽水(加購)','販賣部','飲料',25,null,null,true,true,'披薩加購價',0,42),
('B18','可爾必思(加購)','販賣部','飲料',25,null,null,true,true,'披薩加購價',0,43),
('B19','寶礦力(會員)','販賣部','飲料',30,null,null,true,true,'會員價',0,44),
('B20','汽水(會員)','販賣部','飲料',30,null,null,true,true,'會員價',0,45),
('B21','水(會員)','販賣部','飲料',20,null,null,true,true,'會員價',0,46),
('B22','寶礦力(員工)','販賣部','飲料',20,null,null,true,true,'員工價',0,47),
('B23','汽水(員工)','販賣部','飲料',20,null,null,true,true,'員工價',0,48),
('B24','分解茶(員工)','販賣部','飲料',25,null,null,true,true,'員工價',0,49),
('B25','水(員工)','販賣部','飲料',10,null,null,true,true,'員工價',0,50),
('B26','可爾必思(員工)','販賣部','飲料',10,null,null,true,true,'員工價',0,51),
('B27','波爾茶(員工)','販賣部','飲料',25,null,null,true,true,'員工價',0,52),
('B28','健酪(員工)','販賣部','飲料',20,null,null,true,true,'員工價',0,53),
('B29','水蠻牛(員工)','販賣部','飲料',25,null,null,true,true,'員工價',0,54),
('B30','寶礦力(招待)','販賣部','飲料',0,null,null,true,true,'招待',0,55),
('B31','汽水(招待)','販賣部','飲料',0,null,null,true,true,'招待',0,56),
('B32','分解茶(招待)','販賣部','飲料',0,null,null,true,true,'招待',0,57),
('B33','水(招待)','販賣部','飲料',0,null,null,true,true,'招待',0,58),
('B34','可爾必思(招待)','販賣部','飲料',0,null,null,true,true,'招待',0,59)
on conflict (dept, code) do nothing;
