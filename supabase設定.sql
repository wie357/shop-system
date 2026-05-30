-- ============================================================
-- 販賣部系統:雲端備份用資料表與函式
-- 用法:Supabase 後台 → 左側「SQL Editor」→ 貼上全部 → 按 Run
-- ============================================================

-- 1) 備份資料表(以「店家代碼」為主鍵,pin 當密碼)
create table if not exists public.store_backups (
  code       text primary key,
  pin        text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

-- 2) 開啟 RLS 但「不建立任何政策」→ anon 無法直接讀寫此表(只能透過下面的函式)
alter table public.store_backups enable row level security;

-- 3) 上傳/儲存(會檢查 PIN;代碼不存在則新建,存在且 PIN 正確才覆蓋)
create or replace function public.save_backup(p_code text, p_pin text, p_data jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare existing_pin text;
begin
  if p_code is null or length(trim(p_code)) = 0 then raise exception 'CODE_REQUIRED'; end if;
  if p_pin  is null or length(trim(p_pin))  = 0 then raise exception 'PIN_REQUIRED';  end if;

  select pin into existing_pin from public.store_backups where code = p_code;

  if existing_pin is null then
    insert into public.store_backups(code, pin, data) values (p_code, p_pin, p_data);
    return 'created';
  elsif existing_pin = p_pin then
    update public.store_backups set data = p_data, updated_at = now() where code = p_code;
    return 'updated';
  else
    raise exception 'PIN_MISMATCH';
  end if;
end;
$$;

-- 4) 下載/讀取(PIN 正確才回傳資料)
create or replace function public.load_backup(p_code text, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare r public.store_backups;
begin
  select * into r from public.store_backups where code = p_code;
  if not found then raise exception 'NOT_FOUND'; end if;
  if r.pin <> p_pin then raise exception 'PIN_MISMATCH'; end if;
  return r.data;
end;
$$;

-- 5) 權限:只允許匿名(anon)執行這兩個函式,不能碰資料表
revoke all on function public.save_backup(text, text, jsonb) from public;
revoke all on function public.load_backup(text, text)        from public;
grant  execute on function public.save_backup(text, text, jsonb) to anon;
grant  execute on function public.load_backup(text, text)        to anon;
