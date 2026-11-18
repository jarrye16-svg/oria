-- All fixtures are rolled back; no existing financial data is changed.
begin;
select set_config('request.jwt.claim.sub',(select id::text from auth.users order by created_at desc limit 1),true);
set local role authenticated;
do $$
declare h uuid; g uuid; e uuid; e2 uuid; e3 uuid; saved_at timestamptz; n numeric;
  join_code record; data jsonb;
begin
  h:=public.create_house_with_defaults('QA Oria transação temporária');
  insert into public.goals(house_id,name,target_amount,current_amount,owner_name)
    values(h,'QA reserva',1000,0,'QA') returning id into g;
  insert into public.entries(house_id,title,amount,type,status,competence_month,mode,goal_id)
    values(h,'QA entrada',100,'income','paid',date '2026-11-01','income',g)
    returning id,paid_at into e,saved_at;
  select current_amount into n from public.goals where id=g;
  if n<>100 then raise exception 'QA: depósito inicial %',n; end if;
  update public.entries set amount=150 where id=e;
  select current_amount into n from public.goals where id=g;
  if n<>150 then raise exception 'QA: edição do depósito %',n; end if;
  update public.entries set title='QA entrada editada',paid_at=timestamptz '2000-01-01' where id=e;
  if (select paid_at from public.entries where id=e) is distinct from saved_at then
    raise exception 'QA: data original de pagamento alterada';
  end if;
  update public.entries set status='pending' where id=e;
  if (select current_amount from public.goals where id=g)<>0 then raise exception 'QA: estorno pendente'; end if;
  update public.entries set status='paid' where id=e;
  if (select current_amount from public.goals where id=g)<>150 then raise exception 'QA: nova confirmação'; end if;
  begin
    insert into public.goal_movements(house_id,goal_id,amount,kind) values(h,g,200,'withdraw');
    raise exception 'QA: retirada excessiva foi aceita';
  exception when raise_exception then
    if SQLERRM not like 'Saldo insuficiente%' then raise; end if;
  end;
  insert into public.goal_movements(house_id,goal_id,amount,kind) values(h,g,50,'withdraw');
  if (select current_amount from public.goals where id=g)<>100 then raise exception 'QA: retirada válida'; end if;
  begin
    update public.entries set amount=40 where id=e;
    raise exception 'QA: estorno sem saldo foi aceito';
  exception when raise_exception then
    if SQLERRM not like 'Saldo insuficiente%' then raise; end if;
  end;
  if (select amount from public.entries where id=e)<>150 then raise exception 'QA: edição parcial após erro'; end if;
  insert into public.entries(house_id,title,amount,type,status,competence_month)
    values(h,'QA fatura 1',50,'expense','pending',date '2026-11-01') returning id into e2;
  insert into public.entries(house_id,title,amount,type,status,competence_month)
    values(h,'QA fatura 2',100,'expense','pending',date '2026-11-01') returning id into e3;
  perform public.set_entries_paid(h,array[e2,e3],true);
  if (select count(*) from public.entries where id=any(array[e2,e3]) and status='paid')<>2 then
    raise exception 'QA: pagamento em lote';
  end if;
  begin
    perform public.set_entries_paid(h,array[e2,gen_random_uuid()],false);
    raise exception 'QA: lote inválido foi aceito';
  exception when raise_exception then
    if SQLERRM not like 'Lançamento inválido%' then raise; end if;
  end;
  if (select status from public.entries where id=e2)<>'paid' then raise exception 'QA: lote parcialmente aplicado'; end if;
  data:=jsonb_build_array(jsonb_build_object('id',gen_random_uuid(),'house_id',h,'title','QA CSV',
    'amount',20,'type','expense','status','pending','competence_month','2026-11-01','is_recurring',false));
  perform public.restore_entries(h,data);
  perform public.restore_entries(h,data);
  if (select count(*) from public.entries where house_id=h and title='QA CSV')<>1 then raise exception 'QA: duplicação na restauração'; end if;
  begin
    perform public.restore_entries(h,jsonb_build_array(jsonb_build_object('id',gen_random_uuid(),
      'house_id',gen_random_uuid(),'title','QA inválido','amount',20,'type','expense','status','pending')));
    raise exception 'QA: CSV de outra casa foi aceito';
  exception when raise_exception then
    if SQLERRM not like 'Lançamento inválido%' then raise; end if;
  end;
end; $$;
rollback;
select 'PASS: depósitos, edição, estorno, retirada, data original, lote atômico e CSV. Dados temporários desfeitos.' as resultado;
