#!/usr/bin/env python3
"""HTTP integration checks. Run against an isolated Development instance; writes test rows."""
import html as htmlmod
import os,urllib.request as r,urllib.error,urllib.parse,json,http.cookiejar,re,datetime
BASE=os.environ.get('DOOJA_URL','http://127.0.0.1:5080')
jar=http.cookiejar.CookieJar(); client=r.build_opener(r.HTTPCookieProcessor(jar))
checks=[]
def req(path,method='GET',data=None,token=None,status=200,form=False):
 headers={}
 if data is not None:
  if form:
   body=urllib.parse.urlencode(data).encode();headers['Content-Type']='application/x-www-form-urlencoded'
  else:body=json.dumps(data,ensure_ascii=False).encode();headers['Content-Type']='application/json'
 else:body=None
 if token:headers['Authorization']='Bearer '+token
 try:
  response=client.open(r.Request(BASE+path,body,headers,method=method));code=response.status; text=response.read().decode()
 except urllib.error.HTTPError as e:code=e.code;text=e.read().decode()
 assert code==status,(method,path,code,text[:600]);checks.append(f'{method} {path}: {code}')
 try:return json.loads(text)
 except:return htmlmod.unescape(text)
places=req('/api/places');assert len(places)>=12
assert len(req('/api/places?category='+r.quote('بادل')))>=3
assert req('/api/places/p1')['name']=='ملعب بادل لاونج'
req('/api/bookings',status=401)
req('/api/auth/request-otp','POST',{'phone':'07700000001'})
req('/api/auth/verify','POST',{'phone':'07700000001','code':'0000'},status=400)
u=req('/api/auth/verify','POST',{'phone':'07700000001','code':'1234'});t=u['token'];assert u['role']=='Customer'
req('/api/auth/verify','POST',{'phone':'07700000001','code':'1234'},status=400)
assert 'passwordHash' not in req('/api/auth/me',token=t)
req('/api/owner/dashboard',token=t,status=403)
for path in ['/api/bookings','/api/offers','/api/reviews?placeId=p1','/api/reels','/api/reels/1/comments','/api/favorites','/api/notifications','/api/places/p1/services','/api/places/p1/availability?day=2026-12-21']:
 req(path,token=t)
fav=req('/api/favorites/p2/toggle','POST',token=t);assert fav['saved'];assert not req('/api/favorites/p2/toggle','POST',token=t)['saved']
req('/api/places/p2/follow','POST',token=t);req('/api/places/p2/follow','POST',token=t)
req('/api/reels/1/like','POST',token=t);req('/api/reels/1/like','POST',token=t)
req('/api/reels/1/comments','POST',{'text':'فحص ربط API مع قاعدة البيانات'},token=t)
req('/api/notifications/read-all','POST',token=t)
day=(datetime.date.today()+datetime.timedelta(days=30+int(datetime.datetime.now().timestamp())%300)).isoformat()
b=req('/api/bookings','POST',{'placeId':'p2','day':day,'time':'16:00','hours':2,'people':4,'payMethod':'كاش بالمكان','total':1},token=t,status=201)
assert b['total']==60000 and b['status']=='بانتظار القبول'
req('/api/bookings','POST',{'placeId':'p2','day':day,'time':'17:00','hours':1,'people':4,'payMethod':'كاش بالمكان'},token=t,status=400)
req('/api/auth/request-otp','POST',{'phone':'07700000002'})
o=req('/api/auth/verify','POST',{'phone':'07700000002','code':'1234'});ot=o['token'];assert o['role']=='Owner'
for path in ['/api/owner/dashboard','/api/owner/places','/api/owner/bookings','/api/owner/reviews','/api/owner/offers','/api/owner/services/p1','/api/owner/closed-slots/p1']:
 req(path,token=ot)
req('/api/bookings/'+str(b['id'])+'/cancel','POST',token=ot,status=404)
req('/api/owner/bookings/'+str(b['id'])+'/status','POST',{'status':'مؤكد'},token=ot)
req('/api/owner/bookings/'+str(b['id'])+'/arrive','POST',token=ot)
req('/api/owner/bookings/'+str(b['id'])+'/status','POST',{'status':'مكتمل'},token=ot)
req('/api/bookings/'+str(b['id'])+'/cancel','POST',token=t,status=400)
req('/api/reviews','POST',{'placeId':'p2','bookingId':b['id'],'stars':5,'text':'اختبار حجز حقيقي عبر قاعدة البيانات'},token=t)
req('/api/reviews','POST',{'placeId':'p2','bookingId':b['id'],'stars':5,'text':'مكرر'},token=t,status=400)
# HTML login includes antiforgery and a secure cookie session.
def antiforgery(html):return re.search(r'name="__RequestVerificationToken" type="hidden" value="([^"]+)"',html).group(1)
html=req('/Auth/Login');csrf=antiforgery(html)
html=req('/Auth/Login','POST',{'Phone':'07700000000','Password':'Dooja.Dev!2026','__RequestVerificationToken':csrf},form=True);assert 'كل شي بمكان واحد' in html
for path in ['/','/Places','/Places/Create','/Places/Edit/p1','/Bookings','/Offers','/Offers/Create','/Offers/Edit/o1','/Users','/Users/Create','/Reviews']:
 html=req(path);assert 'Dooja.Dashboard' not in html;assert 'dir="rtl"' in html
req('/Places/Save','POST',{'Name':'no csrf'},form=True,status=400)
# Create an actual place through the MVC form, then find it in public API.
html=req('/Places/Create');csrf=antiforgery(html);pid=re.search(r'id="Id" name="Id" value="([^"]+)"',html).group(1)
owner_id=req('/api/auth/me',token=ot)['id']
html=req('/Places/Save','POST',{'Id':pid,'Name':'مكان فحص التكامل','ImageKey':'padel','Type':'بادل','Area':'بغداد','Dist':'1 كم','Price':12000,'Unit':'ساعة','Kind':'open','Category':'بادل','Phone':'07700000002','OwnerUserId':owner_id,'Active':'true','Featured':'false','__RequestVerificationToken':csrf},form=True)
assert 'تم حفظ المكان' in html,html[:1000]
assert req('/api/places/'+pid)['price']==12000
# Hide test place after confirming the write went through.
html=req('/Places/Edit/'+pid);csrf=antiforgery(html)
req('/Places/Save','POST',{'Id':pid,'Name':'مكان فحص التكامل','ImageKey':'padel','Type':'بادل','Area':'بغداد','Dist':'1 كم','Price':12000,'Unit':'ساعة','Kind':'open','Category':'بادل','Phone':'07700000002','OwnerUserId':owner_id,'Active':'false','Featured':'false','__RequestVerificationToken':csrf},form=True)
req('/api/places/'+pid,status=404)
# Other customer's data is isolated even with a valid bearer token.
req('/api/auth/request-otp','POST',{'phone':'07700000003'})
other=req('/api/auth/verify','POST',{'phone':'07700000003','code':'1234'})['token']
req('/api/bookings/'+str(b['id']),token=other,status=404)
req('/api/bookings/'+str(b['id'])+'/cancel','POST',token=other,status=404)
# Exercise remaining MVC write paths and check the same rows via API.
page=req('/Users/Create');csrf=antiforgery(page)
page=req('/Users/Save','POST',{'Name':'مالك فحص العزل','Phone':'07799999999','Role':'Owner','Governorate':'بغداد','Area':'المنصور','Birth':'2000-01-01','Points':0,'Active':'true','__RequestVerificationToken':csrf},form=True)
assert 'تم حفظ المستخدم' in page,page[page.find('validation'):page.find('validation')+1000]
req('/api/auth/request-otp','POST',{'phone':'07799999999'})
outsider=req('/api/auth/verify','POST',{'phone':'07799999999','code':'1234'})['token']
assert req('/api/owner/places',token=outsider)==[]
req('/api/owner/services/p1',token=outsider,status=403)
req('/api/reviews/1/reply','POST',{'text':'غير مخوّل'},token=outsider,status=403)
page=req('/Offers/Create');csrf=antiforgery(page);oid=re.search(r'id="Id" name="Id" value="([^"]+)"',page).group(1)
page=req('/Offers/Save','POST',{'Id':oid,'PlaceId':'p2','Title':'عرض فحص التكامل','Disc':'خصم مباشر','NewPrice':12000,'OldPrice':30000,'ExpiryText':'اختبار','ExpiresOn':day,'Active':'true','__RequestVerificationToken':csrf},form=True)
assert 'تم حفظ العرض' in page,page[page.find('validation'):page.find('validation')+1000]
assert req('/api/offers/'+oid)['newPrice']==12000
# Booking an offer calculates the price server-side and increments its DB counter.
ob=req('/api/bookings','POST',{'placeId':'p2','offerId':oid,'day':day,'time':'13:00','hours':2,'people':4,'payMethod':'كاش بالمكان'},token=t,status=201)
assert ob['total']==24000 and ob['offerId']==oid
assert req('/api/offers/'+oid)['books']==1
req('/api/bookings/'+str(ob['id'])+'/cancel','POST',token=t)
page=req('/Offers/Edit/'+oid);csrf=antiforgery(page)
req('/Offers/Toggle','POST',{'id':oid,'__RequestVerificationToken':csrf},form=True)
req('/api/offers/'+oid,status=404)
page=req('/Reviews');csrf=antiforgery(page)
page=req('/Reviews/Reply','POST',{'id':1,'text':'رد فحص محفوظ بقاعدة البيانات','__RequestVerificationToken':csrf},form=True)
assert 'رد فحص محفوظ بقاعدة البيانات' in page
service=req('/api/owner/services','POST',{'placeId':'p1','name':'خدمة فحص','price':3000,'unit':'ساعة'},token=ot)
req('/api/owner/services/'+str(service['id']),'DELETE',token=ot,status=204)
slot=req('/api/owner/closed-slots','POST',{'placeId':'p2','day':day,'time':'12:00'},token=ot)
req('/api/bookings','POST',{'placeId':'p2','day':day,'time':'12:00','hours':1,'people':2,'payMethod':'كاش بالمكان'},token=t,status=400)
req('/api/owner/closed-slots/'+str(slot['id']),'DELETE',token=ot,status=204)
print('\n'.join(checks));print(f'PASS: {len(checks)} HTTP checks, SQLite persistence, auth boundaries and Arabic MVC rendering')
