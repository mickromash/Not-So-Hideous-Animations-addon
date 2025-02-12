// ------------------------------------------------------------
// Bolt-Action Rifle
// ------------------------------------------------------------
class BossRifleSpawner:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_SpawnItemEx("HD7mClip",-3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("HD7mClip",3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("HD7mClip",1,0,0,0,0,0,0,SXF_NOCHECKPOSITION);

			let ggg=BossRifle(spawn("BossRifle",pos,ALLOW_REPLACE));
			HDF.TransferSpecials(self,ggg,HDF.TS_ALL);
		}stop;
	}
}
class BossRifle:HDWeapon{
	default{
		weapon.slotnumber 8;
		weapon.slotpriority 1;
		weapon.kickback 15;
		weapon.selectionorder 80;
		inventory.pickupSound "misc/w_pkup";
		inventory.pickupMessage "$PICKUP_BOSSRIFLE";
		weapon.bobrangex 0.28;
		weapon.bobrangey 1.1;
		scale 0.75;
		Obituary "$OB_BOSS";
		hdweapon.barrelsize 40,1,2;
		hdweapon.refid HDLD_BOSS;
		tag "$TAG_BOSS";

		hdweapon.ammo1 "HD7mClip",1;

		hdweapon.loadoutcodes "
			\cucustomchamber - 0/1, whether to reduce jam for less power
			\cufrontreticle - 0/1, whether crosshair scales with zoom
			\cubulletdrop - 0-600, amount of compensation for bullet drop
			\cuzoom - 5-60, 10x the resulting FOV in degrees";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	action void A_ChamberGrit(int amt,bool onlywhileempty=false){
		int ibg=invoker.weaponstatus[BOSSS_GRIME];
		bool customchamber=(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER);
		if(amt>0&&customchamber)amt>>=1;
		if(!onlywhileempty||invoker.weaponstatus[BOSSS_CHAMBER]<1)ibg+=amt;
		else if(!random(0,4))ibg++;
		invoker.weaponstatus[BOSSS_GRIME]=clamp(ibg,0,100);
		//if(hd_debug)A_Log(string.format("Boss grit level: %i",invoker.weaponstatus[BOSSS_GRIME]));
	}
	int pickuprounds;
	override void tick(){
		super.tick();
		drainheat(BOSSS_HEAT,4);
	}
	override double gunmass(){
		return 12;
	}
	override double weaponbulk(){
		return 144+weaponstatus[BOSSS_MAG]*ENC_776_LOADED;
	}
	override void GunBounce(){
		super.GunBounce();
		weaponstatus[BOSSS_GRIME]+=random(-7,3);
		if(weaponstatus[BOSSS_CHAMBER]>2&&!random(0,7))weaponstatus[BOSSS_CHAMBER]-=2;
	}
	int jamchance(){
		int jc=
		weaponstatus[BOSSS_GRIME]
		+(weaponstatus[BOSSS_HEAT]>>2)
		+weaponstatus[BOSSS_CHAMBER]
		;
		if(weaponstatus[0]&BOSSF_CUSTOMCHAMBER)return jc>>5;
		return jc;
	}
	override string,double getpickupsprite(){return "BORFA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD7mClip")));
			if(nextmagloaded<1){
				sb.drawimage("RCLPF0",(-50,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.,scale:(1.2,1.2));
			}else if(nextmagloaded<3){
				sb.drawimage("RCLPE0",(-50,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.2,1.2));
			}else if(nextmagloaded<5){
				sb.drawimage("RCLPD0",(-50,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.2,1.2));
			}else if(nextmagloaded<7){
				sb.drawimage("RCLPC0",(-50,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.2,1.2));
			}else if(nextmagloaded<9){
				sb.drawimage("RCLPB0",(-50,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.2,1.2));
			}else sb.drawimage("RCLPA0",(-50,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.2,1.2));
			sb.drawnum(hpl.countinv("HD7mClip"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);

			int sevenrounds=hpl.countinv("SevenMilAmmo");
			sb.drawimage("TEN7A0",(-62,-4),sb.DI_SCREEN_CENTER_BOTTOM,alpha:sevenrounds?1:0.6,scale:(1.2,1.2));
			sb.drawnum(sevenrounds,-56,-8,sb.DI_SCREEN_CENTER_BOTTOM);

			sevenrounds=hpl.countinv("SevenMilAmmoRecast");
			if(sevenrounds>0){
				sb.drawimage("TEN7A0",(-62,-14),sb.DI_SCREEN_CENTER_BOTTOM,alpha:sevenrounds?1:0.6,scale:(1.2,1.2));
				sb.drawnum(sevenrounds,-56,-18,sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}
		sb.drawwepnum(hdw.weaponstatus[BOSSS_MAG],10);
		sb.drawwepcounter(hdw.weaponstatus[BOSSS_CHAMBER],
			-16,-10,"blank","RBRSA1A5","RBRSA3A7","RBRSA4A6"
		);
		sb.drawstring(
			sb.mAmountFont,string.format("%.1f",hdw.weaponstatus[BOSSS_ZOOM]*0.1),
			(-36,-18),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_DARKGRAY
		);
		sb.drawstring(
			sb.mAmountFont,string.format("%i",hdw.weaponstatus[BOSSS_DROPADJUST]),
			(-16,-18),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_WHITE
		);
		if(hdw.weaponstatus[BOSSF_SAFETY]==1)sb.drawimage("SAFETY",(-22,-9),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));	
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRESHOOT
		..LWPHELP_ALTFIRE..StringTable.Localize("$BOSWH_ALTFIRE")
		..LWPHELP_RELOAD..StringTable.Localize("$BOSWH_RELOAD")
		..LWPHELP_ZOOM.."+"..LWPHELP_FIREMODE..StringTable.Localize("$BOSWH_ZPFMOD")
		..LWPHELP_ZOOM.."+"..LWPHELP_USE..StringTable.Localize("$BOSWH_ZPUSE")
		..LWPHELP_ZOOM.."+"..LWPHELP_DROPONE..StringTable.Localize("$BOSWH_ZPDRON")
		..LWPHELP_ZOOM.."+"..LWPHELP_ALTRELOAD..StringTable.Localize("$BOSWH_ZPALTRELOAD")
		..LWPHELP_ALTFIRE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$BOSWH_AFIREPUNL")
		..LWPHELP_UNLOADUNLOAD
		..LWPHELP_USE.."+"..LWPHELP_FIREMODE..StringTable.Localize("$LWPHELP_SAFETY")
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=Screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-64+bob.y,32,76,
			sb.DI_SCREEN_CENTER
		);
		int Light = Owner.Cursector.LightLevel * 1.75;
		if(owner.player.fixedlightlevel==1)Light = 255;
		sb.drawimage(
			"bsfrntsit",bob*1.14,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"BSBLFTSIT",bob*1.14,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP, col:Color(254-Light, 0,0,0)
		);
		sb.SetClipRect(cx,cy,cw,ch);

		sb.drawimage(
			"bsbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9
		);
		if(CVar.GetCVar("mrnsha_sights", owner.player).GetBool())
		sb.drawimage(
			"bsblksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9, col:Color(254-Light, 0,0,0)
		);

		if(scopeview){
			int scaledwidth=89;
			int scaledyoffset=60;
			double degree=0.1*hdw.weaponstatus[BOSSS_ZOOM];
			double deg=1/degree;
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(-44+bob.x,16+bob.y,scaledwidth,scaledwidth,
				sb.DI_SCREEN_CENTER
			);

			sb.fill(color(255,0,0,0),
				bob.x-44,scaledyoffset+bob.y-44,
				88,88,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);

			texman.setcameratotexture(hpc,"HDXCAM_BOSS",degree);
			let cam     = texman.CheckForTexture("HDXCAM_BOSS",TexMan.Type_Any);
			let reticle = texman.CheckForTexture("bossret1",TexMan.Type_Any);

			vector2 frontoffs=(0,scaledyoffset)+bob*3;

			double camSize  = texman.GetSize(cam);
			sb.DrawCircle(cam, frontoffs, 0.125,usePixelRatio:true);

			//[2022-09-17] there's a glitch in GZDoom where if the reticle would be drawn completely off screen,
			//the cliprect is ignored. The figure is a product of trial and error.
			if((bob.y/fov)<0.4){
				let reticleScale = camSize / texman.GetSize(reticle);
				if(hdw.weaponstatus[0]&BOSSF_FRONTRETICLE){
					sb.DrawCircle(reticle, frontoffs, .5*reticleScale, bob*deg*5-bob, 1.6*deg);
				}else{
					sb.DrawCircle(reticle, (0,scaledyoffset)+bob, .5*reticleScale,uvScale:.5);
				}
			}

			//let holeScale    = camSize / texman.GetSize(hole);
			//let hole    = texman.CheckForTexture("scophole",TexMan.Type_Any);
			//sb.DrawCircle(hole, (0, scaledyoffset) + bob, .5 * holeScale, bob * 5, 1.5);


			screen.SetClipRect(cx,cy,cw,ch);

			sb.drawimage(
				"bossscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1.24,1.24)
			);
			sb.drawstring(
				sb.mAmountFont,string.format("%.1f",degree),
				(6+bob.x,105+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_BLACK
			);
			sb.drawstring(
				sb.mAmountFont,string.format("%i",hdw.weaponstatus[BOSSS_DROPADJUST]),
				(6+bob.x,9+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_BLACK
			);
		}
		// the scope display is in 10ths of an arcminute.
		// one dot = 6 arcminutes.
	}
	override void consolidate(){
		weaponstatus[BOSSS_GRIME]=random(0,20);
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(
				owner.countinv("SevenMilAmmoRecast")
				&&(
					!(
						owner.player
						&&owner.player.cmd.buttons&BT_ZOOM
					)||!owner.countinv("SevenMilAmmo")
				)
			)owner.A_DropInventory("SevenMilAmmoRecast",10);
			else if(owner.countinv("SevenMilAmmo"))owner.A_DropInventory("SevenMilAmmo",10);
			else owner.A_DropInventory("HD7mClip",1);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_SetInventory("SevenMilAmmo",11);
		owner.A_TakeInventory("SevenMilBrass");
		owner.A_TakeInventory("FourMilAmmo");
		ForceOneBasicAmmo("HD7mClip");
	}

	int handrounds;
	override void DetachFromOwner(){
		if(handrounds>0){
			actor dropper=self;
			if(owner)dropper=owner;

			int fullets=handrounds/100;

			if(fullets>0)dropper.A_DropItem("SevenMilAmmo",fullets);

			handrounds=(handrounds%100)-fullets;
			if(handrounds>0)dropper.A_DropItem("SevenMilAmmoRecast",handrounds);
		}
		super.DetachFromOwner();
	}

	states{
	select0:
		BARG A 0;
		goto select0bfg;
	deselect0:
		BARG A 0;
		goto deselect0big;

	Safety:
		---- A 0 {A_StartSound("weapons/fmswitch",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		if(invoker.weaponstatus[BOSSF_SAFETY]==1)invoker.weaponstatus[BOSSF_SAFETY]=0;
		else invoker.weaponstatus[BOSSF_SAFETY]=1;}
		Goto Nope;
		
	ready:
		BARG A 1{
			if(pressingzoom()){
				if(player.cmd.buttons&BT_USE){
					A_ZoomAdjust(BOSSS_DROPADJUST,0,1600,BT_USE);
				}else if(invoker.weaponstatus[0]&BOSSF_FRONTRETICLE)A_ZoomAdjust(BOSSS_ZOOM,12,40);
				else A_ZoomAdjust(BOSSS_ZOOM,5,60);
				A_WeaponReady(WRF_NONE);
			}else if(pressinguse()&&pressingfiremode())setweaponstate("Safety"); 
			else A_WeaponReady(WRF_ALL);
		}
		goto readyend;
	user3:
		---- A 0 A_MagManager("HD7mClip");
		goto ready;
	fire:
		---- A 0 A_JumpIf(invoker.weaponstatus[BOSSF_SAFETY]==1,"Nope");
		BARG A 1 A_JumpIf(invoker.weaponstatus[BOSSS_CHAMBER]==2,"shoot");
		goto ready;
	shoot:
		BARG A 1{
			bool recast=invoker.weaponstatus[0]&BOSSF_RECAST;
			A_Gunflash();
			invoker.weaponstatus[BOSSS_CHAMBER]=1;
			invoker.weaponstatus[0]&=~BOSSF_RECAST;
			A_StartSound("weapons/bigrifle2",CHAN_WEAPON,CHANF_OVERLAP,
				pitch:!(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER)?1.1:1.
			);
			A_AlertMonsters();

			HDBulletActor.FireBullet(self,recast?"HDB_776r":"HDB_776",
				aimoffy:(-HDCONST_GRAVITY/1000.)*invoker.weaponstatus[BOSSS_DROPADJUST],
				speedfactor:(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER)?0.99:1.07
			);
			A_MuzzleClimb(
				0,0,
				-frandom(0.2,0.4),-frandom(0.6,1.),
				-frandom(0.4,0.7),-frandom(1.2,2.1),
				-frandom(0.4,0.7),-frandom(1.2,2.1)
			);
		}
		BARG F 1;
		BARG F 1 A_JumpIf(gunbraced(),"ready");
		goto ready;
	flash:
		BARF A 1 bright{
			A_Light1();
			HDFlashAlpha(-96);
			A_ZoomRecoil(0.93);
			A_ChamberGrit(randompick(0,0,0,0,0,1,1,1,1,-1));
		}
		TNT1 A 0 A_Light0();
		stop;
	altfire:
		BARG A 1 A_WeaponBusy();
		BARG B 2 A_JumpIf(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER,1);
		BARG B 1 A_JumpIf(invoker.weaponstatus[BOSSS_CHAMBER]>2,"jamderp");
		BARG B 1 A_MuzzleClimb(-frandom(0.06,0.1),-frandom(0.3,0.5));
		BARG B 0 A_ChamberGrit(randompick(0,0,0,0,-1,1,2),true);
		BARG B 0 A_Refire("chamber");
		goto ready;
	althold:
		BARG E 1 A_WeaponReady(WRF_NOFIRE);
		BARG E 1{
			A_ClearRefire();
			bool chempty=invoker.weaponstatus[BOSSS_CHAMBER]<1;
			if(pressingunload()){
				if(chempty){
					return resolvestate("altholdclean");
				}else{
					invoker.weaponstatus[0]|=BOSSF_UNLOADONLY;
					return resolvestate("loadchamber");
				}
			}else if(pressingreload()){
				if(
					!chempty
				){
					invoker.weaponstatus[0]|=BOSSF_UNLOADONLY;
					return resolvestate("loadchamber");
				}else if(
					countinv("SevenMilAmmo")
					||countinv("SevenMilAmmoRecast")
				){
					invoker.weaponstatus[0]&=~BOSSF_UNLOADONLY;
					return resolvestate("loadchamber");
				}
			}
			if(pressingaltfire())return resolvestate("althold");
			return resolvestate("altholdend");
		}
	altholdend:
		BARG E 0 A_StartSound("weapons/boltfwd",8);
		BARG DC 2 A_WeaponReady(WRF_NOFIRE);
		BARG B 3{
			A_WeaponReady(WRF_NOFIRE);
			if(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER)A_SetTics(1);
		}
		goto ready;
	loadchamber:
		BARG E 1 offset(2,36) A_ClearRefire();
		BARG E 1 offset(3,38);
		BARG E 1 offset(5,42);
		BARG E 1 offset(8,48) A_StartSound("weapons/pocket",9);
		BARG E 1 offset(9,52) A_MuzzleClimb(frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2);
		BARG E 2 offset(8,60);
		BARG E 2 offset(7,72);
		TNT1 A 18 A_StartSound("weapons/pocket",9);
		TNT1 A 4{
			A_StartSound("weapons/bossload",8,volume:0.7);
			if(invoker.weaponstatus[0]&BOSSF_UNLOADONLY){
				bool recast=invoker.weaponstatus[0]&BOSSF_RECAST;
				int chm=invoker.weaponstatus[BOSSS_CHAMBER];
				invoker.weaponstatus[BOSSS_CHAMBER]=0;
				invoker.weaponstatus[0]&=~BOSSF_RECAST;
				if(
					chm<2
					||A_JumpIfInventory(recast?"SevenMilAmmoRecast":"SevenMilAmmo",0,"null")
				){
					class<actor> whatkind=chm==2?
						(recast?"HDLoose7mmRecast":"HDLoose7mm")
						:"HDSpent7mm"
					;
					actor rrr=spawn(whatkind,pos+(cos(angle)*10,sin(angle)*10,height-12),ALLOW_REPLACE);
					rrr.angle=angle;rrr.A_ChangeVelocity(1,2,1,CVF_RELATIVE);
				}else HDF.Give(self,"SevenMilAmmo",1);
				A_ChamberGrit(randompick(0,0,0,0,-1,1),true);
			}else{
				class<inventory> rndtp="SevenMilAmmo";
				if(!countinv(rndtp)){
					invoker.weaponstatus[0]|=BOSSF_RECAST;
					rndtp="SevenMilAmmoRecast";
				}
				A_TakeInventory(rndtp,1,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[BOSSS_CHAMBER]=2;
			}
		} 
		BARG E 2 offset(7,72);
		BARG E 2 offset(8,60);
		BARG E 1 offset(6,52);
		BARG E 1 offset(5,42);
		BARG E 1 offset(4,38);
		BARG E 1 offset(3,35);
		goto althold;
	altholdclean:
		BARG E 1 offset(2,36) A_ClearRefire();
		BARG E 1 offset(3,38);
		BARG E 1 offset(5,41) A_Log(StringTable.Localize("$BOSS_CLEANS"),true);
		BARG E 1 offset(8,44) A_StartSound("weapons/pocket",9);
		BARG E 1 offset(7,50) A_MuzzleClimb(frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2);
		TNT1 A 3 A_StartSound("weapons/pocket",10);
		TNT1 AAAA 4 A_MuzzleClimb(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2));
		TNT1 A 3 A_StartSound("weapons/pocket",9);
		TNT1 AAAA 4 A_MuzzleClimb(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2));
		TNT1 A 40{
			A_StartSound("weapons/pocket",9);
			int amt=invoker.weaponstatus[BOSSS_GRIME];
			string amts=StringTable.Localize("$BOSS_CLEAN1");
			if(amt>40)amts=StringTable.Localize("$BOSS_CLEAN2");
			else if(amt>30)amts=StringTable.Localize("$BOSS_CLEAN3");
			else if(amt>20)amts=StringTable.Localize("$BOSS_CLEAN4");
			else if(amt>10)amts=StringTable.Localize("$BOSS_CLEAN5");

			/*static const */string cleanverbs[]={StringTable.Localize("$BOSS_EXTRACT"),StringTable.Localize("$BOSS_SCRAPEOFF"),StringTable.Localize("$BOSS_WIPEAWAY"),StringTable.Localize("$BOSS_CAREREMOVE"),StringTable.Localize("$BOSS_DUMPOUT"),StringTable.Localize("$BOSS_PICKOUT"),StringTable.Localize("$BOSS_BLOWOFF"),StringTable.Localize("$BOSS_SHAKEOUT"),StringTable.Localize("$BOSS_SCRUBOFF"),StringTable.Localize("$BOSS_FISH")};
			/*static const */string contaminants[]={StringTable.Localize("$BOSS_SOMEDUST"),StringTable.Localize("$BOSS_ALODUST"),StringTable.Localize("$BOSS_ABOPOWDER"),StringTable.Localize("$BOSS_DAOPOWDER"),StringTable.Localize("$BOSS_SEXGREASE"),StringTable.Localize("$BOSS_ALOSOOT"),StringTable.Localize("$BOSS_SOMEIRON"),StringTable.Localize("$BOSS_HAIR"),StringTable.Localize("$BOSS_EYELASH"),StringTable.Localize("$BOSS_BLOOD"),StringTable.Localize("$BOSS_RUST"),StringTable.Localize("$BOSS_CRUMB"),StringTable.Localize("$BOSS_DEADSOME"),StringTable.Localize("$BOSS_ASHES"),StringTable.Localize("$BOSS_SKIN"),StringTable.Localize("$BOSS_FLUID"),StringTable.Localize("$BOSS_WOWSOME"),StringTable.Localize("$BOSS_BOOGER"),StringTable.Localize("$BOSS_FECAL"),StringTable.Localize("$BOSS_BULLETSIMPACT"),StringTable.Localize("$BOSS_JAM"),StringTable.Localize("$BOSS_HUSK"),StringTable.Localize("$BOSS_SFLESH"),StringTable.Localize("$BOSS_CRYSTAL"),StringTable.Localize("$BOSS_SPACEANT"),StringTable.Localize("$BOSS_TRANSISTOR"),StringTable.Localize("$BOSS_TINBOSS"),StringTable.Localize("$BOSS_FILM")};
			/*static const */string actionparts[]={StringTable.Localize("$BOSS_BOLTCAR"),StringTable.Localize("$BOSS_MAINEXTRACTOR"),StringTable.Localize("$BOSS_AUXEXTRACTOR"),StringTable.Localize("$BOSS_CAMPIN"),StringTable.Localize("$BOSS_BOLTHEAD"),StringTable.Localize("$BOSS_STRIKER"),StringTable.Localize("$BOSS_SPRING"),StringTable.Localize("$BOSS_EJECTSLOT"),StringTable.Localize("$BOSS_STRIKERSPRING"),StringTable.Localize("$BOSS_EJSPRING")};
			for(int i=amt;i>0;i-=random(8,16))amts.appendformat(StringTable.Localize("$BOSS_FINLINE"),
				cleanverbs[random(0,cleanverbs.size()-1)],
				contaminants[random(0,random(0,contaminants.size()-1))],
				actionparts[random(0,random((actionparts.size()>>1),actionparts.size()-1))]
			);
			amts=HDMath.BuildVariableString(amts);
			amts.appendformat("\n");

			amt=randompick(-3,-5,-5,-random(8,16));

			A_ChamberGrit(amt,true);
			amt=invoker.weaponstatus[BOSSS_GRIME];
			if(amt>40)amts.appendformat(StringTable.Localize("$BOSS_CLENF1"));
			else if(amt>30)amts.appendformat(StringTable.Localize("$BOSS_CLENF2"));
			else if(amt>20)amts.appendformat(StringTable.Localize("$BOSS_CLENF3"));
			else if(amt>10)amts.appendformat(StringTable.Localize("$BOSS_CLENF4"));
			else amts.appendformat(StringTable.Localize("$BOSS_CLENF5"));
			A_Log(amts,true);
		}
		BARG E 1 offset(7,52);
		BARG E 1 offset(8,48);
		BARG E 1 offset(5,42);
		BARG E 1 offset(3,38);
		BARG E 1 offset(2,36);
		goto althold;
	jam:
		BARG A 0{
			int chm=invoker.weaponstatus[BOSSS_CHAMBER];
			if(chm<1)setweaponstate("chamber");
			else if(chm<3)invoker.weaponstatus[BOSSS_CHAMBER]+=2;
		}
	jamderp:
		BARG A 0 A_StartSound("weapons/rifleclick",8,CHANF_OVERLAP);
		BARG D 1 offset(4,38);
		BARG D 2 offset(2,36);
		BARG D 2 offset(4,38)A_MuzzleClimb(frandom(-0.5,0.6),frandom(-0.3,0.6));
		BARG D 3 offset(2,36){
			A_MuzzleClimb(frandom(-0.5,0.6),frandom(-0.3,0.6));
			if(random(0,invoker.jamchance())<12){
				setweaponstate("chamber");
				if(invoker.weaponstatus[BOSSS_CHAMBER]>2)  
					invoker.weaponstatus[BOSSS_CHAMBER]-=2;
			}
		}
		BARG D 2 offset(4,38);
		BARG D 3 offset(2,36);
		BARG A 0 A_Refire("jamderp");
		goto ready;
	chamber:
		BARG C 2{
			if(
				random(0,max(2,invoker.weaponstatus[BOSSS_GRIME]>>3))
				&&invoker.weaponstatus[BOSSS_CHAMBER]>2
			){
				invoker.weaponstatus[BOSSS_CHAMBER]+=2;
				A_MuzzleClimb(
					-frandom(0.6,2.3),-frandom(0.6,2.3),
					-frandom(0.6,1.3),-frandom(0.6,1.3),
					-frandom(0.6,1.3),-frandom(0.6,1.3)
				);
				setweaponstate("jamderp");
			}else A_StartSound("weapons/boltback",8);
		}
		BARG D 2 offset(1,34)A_JumpIf(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER,1);
		BARG D 1 offset(2,36){
			if(gunbraced())A_MuzzleClimb(
				frandom(-0.1,0.3),frandom(-0.1,0.3)
			);else A_MuzzleClimb(
				frandom(-0.2,0.8),frandom(-0.4,0.8)
			);
			int jamch=invoker.jamchance();
			if(hd_debug)A_Log("jam chance: "..jamch);
			if(random(0,100)<jamch)setweaponstate("jam");
		}
		BARG D 2 offset(1,34){
			//eject
			int chm=invoker.weaponstatus[BOSSS_CHAMBER];
			bool recast=invoker.weaponstatus[0]&BOSSF_RECAST;
			invoker.weaponstatus[0]&=~BOSSF_RECAST;
			class<actor> rndtp=chm==1?"HDSpent7mm":recast?"HDLoose7mmRecast":"HDLoose7mm";
			double cp=cos(pitch);
			double sp=sin(pitch);
			actor rrr=null;
			if(chm>=1){
				vector3 gunofs=HDMath.RotateVec3D((10,-1,0),angle,pitch);
				actor rrr=spawn(rndtp,(pos.xy,pos.z+height*0.85)+gunofs+viewpos.offset);
				rrr.target=self;
				rrr.angle=angle;
				rrr.vel=HDMath.RotateVec3D((1,-4,2),angle,pitch);
				if(chm==1)rrr.vel*=1.3;
				rrr.vel+=vel;
			}


			//cycle new
			int bbm=invoker.weaponstatus[BOSSS_MAG];
			if(bbm>0){
				if(
					HD7mMag.CheckRecast(bbm,invoker.weaponstatus[BOSSS_RECASTS])
				){
					invoker.weaponstatus[BOSSS_RECASTS]--;
					invoker.weaponstatus[0]|=BOSSF_RECAST;
				}
				invoker.weaponstatus[BOSSS_CHAMBER]=2;
				invoker.weaponstatus[BOSSS_MAG]--;
			}else invoker.weaponstatus[BOSSS_CHAMBER]=0;
		}
		BARG E 1 A_WeaponReady(WRF_NOFIRE);
		BARG E 0 A_Refire("althold");
		goto altholdend;

	reload:
		---- A 0 A_JumpIf(PressingZoom(), "CheckMag");
		---- A 0{invoker.weaponstatus[0]&=~BOSSF_DONTUSECLIPS;}
		goto reloadstart;
	altreload:
		---- A 0{invoker.weaponstatus[0]|=BOSSF_DONTUSECLIPS;}
		goto reloadstart;
	reloadstart:
		BARG A 1 offset(0,34);
		BARG A 1 offset(2,36);
		BARG A 1 offset(4,40);
		BARG A 2 offset(8,42){
			A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP,0.9,pitch:0.95);
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
		}
		BARG A 4 offset(14,46){
			A_StartSound("weapons/bossloadm",8,CHANF_OVERLAP);
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
		}
		BARG A 2{
			int mg=invoker.weaponstatus[BOSSS_MAG];
			if(mg==10){setweaponstate("reloaddone");}
			else if(invoker.weaponstatus[0]&BOSSF_DONTUSECLIPS)setweaponstate("loadhand");
			else if(
				(
					mg<1
					||(
						!countinv("SevenMilAmmo")
						&&!countinv("SevenMilAmmoRecast")
					)
				)&&!HDMagAmmo.NothingLoaded(self,"HD7mClip")
			)setweaponstate("loadclip");
		}
	loadhand:
		BARG A 0 A_JumpIfInventory("SevenMilAmmo",1,"loadhandloop");
		BARG A 0 A_JumpIfInventory("SevenMilAmmoRecast",1,"loadhandloop");
		goto reloaddone;
	HandLoadRound:
		BOSR F 1 A_OverLayOffset(26, 18, 28);
		BOSR F 1 A_OverLayOffset(26, 9, 12);
		Stop;
	HandLoadingRound:
		BOSR F 1 A_OverLayOffset(26, 2, 2);
		BOSR F 1 A_OverLayOffset(26, 1, 1);
		BOSR F 1 A_OverLayOffset(26, 0, 0);
		BOSR F 1 A_OverLayOffset(26, 1, 1);
		BOSR F 1 A_OverLayOffset(26, 2, 2);
		BOSR F 1 A_OverLayOffset(26, 2, 3);
		Stop;
	HandLoadRoundEnd:
		BOSR F 1 A_OverLayOffset(26, 9, 12);
		BOSR F 1 A_OverLayOffset(26, 18, 28);
		Stop;	
	loadhandloop:
		BARG A 2{
			class<inventory> rndtp="SevenMilAmmo";
			if(
				!countinv(rndtp)
				||(
					countinv("SevenMilAmmoRecast")
					&&pressingzoom()
				)
			)rndtp="SevenMilAmmoRecast";
			int hnd=min(
				countinv(rndtp),3,
				10-invoker.weaponstatus[BOSSS_MAG]
			);
			if(hnd<1){
				setweaponstate("reloaddone");
				return;
			}else{
				A_TakeInventory(rndtp,hnd,TIF_NOTAKEINFINITE);
				invoker.handrounds=hnd;
				if(rndtp=="SevenMilAmmo")invoker.handrounds+=hnd*100;
				A_StartSound("weapons/pocket",9);
			}
		}
		BARG A 0 A_OverLay(26, "HandLoadRound");
		BARG A 2;
	loadone:
		BARG A 2 offset(16,50) A_JumpIf(invoker.handrounds<1,"loadhandnext");
		BARG A 0 A_OverLay(26, "HandLoadingRound");
		BARG A 4 offset(16,50){
			if(invoker.handrounds>100)invoker.handrounds-=100;
			else invoker.weaponstatus[BOSSS_RECASTS]++;

			invoker.handrounds--;
			invoker.weaponstatus[BOSSS_MAG]++;

			A_StartSound("weapons/rifleclick2",8);
		}loop;
	loadhandnext:
		BARG A 0 A_OverLay(26, "HandLoadRoundEnd");
		BARG A 6 offset(16,48){
			if(
				PressingReload()||
				PressingFire()||
				PressingAltFire()||
				PressingZoom()||
				(
					!countinv("SevenMilAmmo")	//don't strip clips automatically
					&&!countinv("SevenMilAmmoRecast")
				)
			)setweaponstate("reloaddone");
			else A_StartSound("weapons/pocket",9);
		}
		BARG A 0 A_OverLay(26, "HandLoadRound");
		BARG A 2;
		goto loadhandloop;
	loadclip:
		BARG A 0 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>9,"reloaddone");
		BARG A 3 offset(16,40){
			let ccc=hdmagammo(findinventory("HD7mClip"));
			if(ccc){
				//find the last mag that has anything in it and load from that
				bool fullmag=false;
				int magindex=-1;
				for(int i=ccc.mags.size()-1;i>=0;i--){
					if(ccc.mags[i]>=10)fullmag=true;
					if(magindex<0&&ccc.mags[i]>0)magindex=i;
					if(fullmag&&magindex>0)break;
				}
				if(magindex<0){
					setweaponstate("reloaddone");
					return;
				}

				//load the whole clip at once if possible
				if(
					fullmag
					&&invoker.weaponstatus[BOSSS_MAG]<1
				){
					setweaponstate("loadwholeclip");
					return;
				}

				//strip one round and load it
				A_StartSound("weapons/rifleclick2",CHAN_WEAPONBODY);

				if(HD7mMag.CheckRecast(ccc.mags[magindex])){
					invoker.weaponstatus[BOSSS_RECASTS]++;
				}else{
					ccc.mags[magindex]-=100;
				}
				invoker.weaponstatus[BOSSS_MAG]++;
				ccc.mags[magindex]--;
			}
		}
		BARG A 5 offset(16,52) A_JumpIf(
			PressingReload()||
			PressingFire()||
			PressingAltFire()||
			PressingZoom()
		,"reloaddone");
		loop;
	ClipAmmoLoading:
		BOSR G 1 A_OverLayOffset(25, 0, 0);
		BOSR G 1 A_OverLayOffset(25, 0, 0);
		BOSR G 3 A_OverLayOffset(25, -0, 0);
		BOSR G 3 A_OverLayOffset(25, -4, 0);
		BOSR G 3 A_OverLayOffset(25, -8, 0);
		BOSR G 2 A_OverLayOffset(25, -12, 0);
		BOSR G 2 A_OverLayOffset(25, -16, 0);
		BOSR G 2 A_OverLayOffset(25, -18, 0);
		BOSR G 1 A_OverLayOffset(25, -20, 0);
		BOSR G 1 A_OverLayOffset(25, -23, 0);
		BOSR G 1 A_OverLayOffset(25, -25, 0);
		Stop;
	HandLoadClip:
		BOSR A 1 A_OverLayOffset(-26, 26, 30);
		BOSR A 1 A_OverLayOffset(-26, 17, 20);
		BOSR B 1 A_OverLayOffset(-26, 10, 10);
		BOSR C 1 A_OverLayOffset(-26, 4, 0);
		BOSR C 1 A_OverLayOffset(-26, 0, 0);
		Stop;
	ClipLoad:
		TNT1 A 0 A_JumpIf(Health<1,"ClipDie");
		BOSR D 1 A_OverLayOffset(26, 0, 0);
		Loop;
	ClipDie:
		TNT1 A 1 {HDMagAmmo.SpawnMag(self,"HD7mClip",0);}
	Non:
		TNT1 A 0;
		Stop;
	ClipFall:
		BOSR D 1 A_OverLayOffset(26, 3, 7);
		BOSR D 1 A_OverLayOffset(26, 6, 10);
		BOSR D 1 A_OverLayOffset(26, 9, 17);
		BOSR D 1 A_OverLayOffset(26, 12, 30);
		Stop;
	BossOverLay:
		BARG A 1 A_JumpIf(Health<1,"Non");
		Loop;
	HandLoadingClip:
		BOSR E 1 A_OverLayOffset(-27, -5, 0);
		BOSR E 1 A_OverLayOffset(-27, 0, 0);
		BOSR E 3 A_OverLayOffset(-27, -4, 0);
		BOSR E 3 A_OverLayOffset(-27, -8, 0);
		BOSR E 3 A_OverLayOffset(-27, -12, 0);
		BOSR E 2 A_OverLayOffset(-27, -16, 0);
		BOSR E 2 A_OverLayOffset(-27, -20, 0);
		BOSR E 2 A_OverLayOffset(-27, -23, 0);
		BOSR E 1 A_OverLayOffset(-27, -25, 0);
		BOSR E 1 A_OverLayOffset(-27, -26, 0);
		BOSR E 1 A_OverLayOffset(-27, -28, 0);
		BOSR E 2 A_OverLayOffset(-27, -24, 6);
		BOSR E 2 A_OverLayOffset(-27, -20, 12);
		TNT1 A 2;
		TNT1 A 0 A_OverLay(26, "ClipFall");
		Stop;
	loadwholeclip:
		BARG A 5 offset(11,40) A_OverLay(-26, "HandLoadClip"); 
		BARG A 0 A_StartSound("weapons/rifleclick2",8);
		---- A 0 A_OverLay(27, "BossOverLay"); 
		---- A 0 A_OverLay(26, "ClipLoad"); 
		---- A 0 A_OverLay(25, "ClipAmmoLoading"); 
		---- A 0 A_OverLay(-27, "HandLoadingClip"); 
		BARG A 2 offset(11,40);
		BARG AAA 3 offset(12,41) A_StartSound("weapons/rifleclick2",8,pitch:1.01);
		BARG AAA 2 offset(11,40) A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP,pitch:1.02);
		BARG AAA 1 offset(10,39) A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP,pitch:1.02);
		BARG A 2 offset(9,36){
			A_OverLay(27, "Non");
			A_StartSound("weapons/rifleclick",CHAN_WEAPONBODY);
			let ccc=hdmagammo(findinventory("HD7mClip"));
			if(ccc){
				int roundraw=ccc.TakeMag(true);
				int roundcount=roundraw%100;
				int reccount=roundcount-(roundraw/100);

				invoker.weaponstatus[BOSSS_RECASTS]=reccount;
				invoker.weaponstatus[BOSSS_MAG]=roundcount;

				if(pressingreload()){
					ccc.addamag(0);
					A_SetTics(10);
					A_StartSound("weapons/pocket",CHAN_POCKETS);
				}else HDMagAmmo.SpawnMag(self,"HD7mClip",0);
			}
		}goto reloaddone;
	reloaddone:
		BARG A 1 offset(4,40);
		BARG A 1 offset(2,36);
		BARG A 1 offset(0,34);
		goto nope;
	unload:
		BARG A 1 offset(0,34);
		BARG A 1 offset(2,36);
		BARG A 1 offset(4,40);
		BARG A 2 offset(8,42){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound("weapons/rifleclick2",8);
		}
		BARG A 4 offset (14,46){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound("weapons/bossloadm",8);
		}
	unloadloop:
		BARG A 4 offset(3,41){
			if(invoker.weaponstatus[BOSSS_MAG]<1)setweaponstate("unloaddone");
			else{
				int bbm=invoker.weaponstatus[BOSSS_MAG];
				bool recast=HD7mMag.CheckRecast(bbm,invoker.weaponstatus[BOSSS_RECASTS]);
				class<inventory> rndtp=recast?"SevenMilAmmoRecast":"SevenMilAmmo";

				A_StartSound("weapons/rifleclick2",8);
				invoker.weaponstatus[BOSSS_MAG]--;
				if(recast)invoker.weaponstatus[BOSSS_RECASTS]--;
				if(A_JumpIfInventory(rndtp,0,"null")){
					A_SpawnItemEx(
						recast?"HDLoose7mmRecast":"HDLoose7mm",cos(pitch)*8,0,height-7-sin(pitch)*8,
						cos(pitch)*cos(angle-40)*1+vel.x,
						cos(pitch)*sin(angle-40)*1+vel.y,
						-sin(pitch)*1+vel.z,
						0,SXF_ABSOLUTEMOMENTUM|
						SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);
				}else A_GiveInventory(rndtp,1);
			}
		}
		BARG A 2 offset(2,42);
		BARG A 0{
			if(
				PressingReload()||
				PressingFire()||
				PressingAltFire()||
				PressingZoom()
			)setweaponstate("unloaddone");
		}loop;
	unloaddone:
		BARG A 2 offset(2,42);
		BARG A 3 offset(3,41);
		BARG A 1 offset(4,40) A_StartSound("weapons/rifleclick",8);
		BARG A 1 offset(2,36);
		BARG A 1 offset(0,34);
		goto ready;
	CheckMag:
		CheckMag:
		BARG B 2 A_Jumpif(!PressingReload(), "Nope");
		---- B 0 {if(invoker.weaponstatus[BOSSS_MAG]>0)A_Overlay(102, "Dumb");if(invoker.weaponstatus[BOSSS_CHAMBER]==2)A_Overlay(103, "Dumb2");}
		Loop;
	Dumb:
		STUP A 0 A_OverLayOffset(102,29,24);
		STUP A 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>1,1);
		Stop;
		STUP B 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>2,1);
		Stop;
		STUP C 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>3,1);
		Stop;
		STUP D 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>4,1);
		Stop;
		STUP E 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>5,1);
		Stop;
		STUP F 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>6,1);
		Stop;
		STUP G 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>7,1);
		Stop;
		STUP H 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>8,1);
		Stop;
		STUP I 5 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>9,1);
		Stop;
		STUP J 5;
		Stop;
	Dumb2:
		STUP A 0 A_OverLayOffset(103, 32, 22);
		STUP Q 5;
		Stop;	

	spawn:
		BORF A -1;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[BOSSS_CHAMBER]=2;
		weaponstatus[BOSSS_MAG]=10;
		weaponstatus[BOSSS_RECASTS]=0;
		if(!idfa){
			weaponstatus[BOSSS_HEAT]=0;
		}
		if(!owner){
			if(randompick(0,0,1))weaponstatus[0]&=~BOSSF_FRONTRETICLE;
				else weaponstatus[0]|=BOSSF_FRONTRETICLE;
			if(random(0,3))weaponstatus[0]&=~BOSSF_CUSTOMCHAMBER;
				else weaponstatus[0]|=BOSSF_CUSTOMCHAMBER;
			weaponstatus[BOSSS_ZOOM]=20;
			weaponstatus[BOSSS_DROPADJUST]=127;
		}
	}
	override void loadoutconfigure(string input){
		int customchamber=getloadoutvar(input,"customchamber",1);
		if(!customchamber)weaponstatus[0]&=~BOSSF_CUSTOMCHAMBER;
		else if(customchamber>0)weaponstatus[0]|=BOSSF_CUSTOMCHAMBER;

		int frontreticle=getloadoutvar(input,"frontreticle",1);
		if(!frontreticle)weaponstatus[0]&=~BOSSF_FRONTRETICLE;
		else if(frontreticle>0)weaponstatus[0]|=BOSSF_FRONTRETICLE;

		int bulletdrop=getloadoutvar(input,"bulletdrop",3);
		if(bulletdrop>=0)weaponstatus[BOSSS_DROPADJUST]=clamp(bulletdrop,0,1600);

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>0)weaponstatus[BOSSS_ZOOM]=
			(weaponstatus[0]&BOSSF_FRONTRETICLE)?
			clamp(zoom,12,40):
			clamp(zoom,5,60);
	}
}
enum bossstatus{
	BOSSF_FRONTRETICLE=1,
	BOSSF_CUSTOMCHAMBER=2,
	BOSSF_UNLOADONLY=4,
	BOSSF_SAFETY=7,
	BOSSF_DONTUSECLIPS=8,
	BOSSF_RECAST=16,

	BOSSS_CHAMBER=1, //0=nothing, 1=brass, 2=loaded, 3/4=jammed brass/round
	BOSSS_MAG=2,
	BOSSS_ZOOM=3,
	BOSSS_DROPADJUST=4,
	BOSSS_HEAT=5,
	BOSSS_GRIME=6,
	BOSSS_RECASTS=7,
}


