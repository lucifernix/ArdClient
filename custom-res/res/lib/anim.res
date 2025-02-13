Haven Resource 1 src 7	  BlendMod.java /* Preprocessed source code */
package haven.res.lib.anim;

import java.util.*;
import haven.*;
import haven.Skeleton.*;

public abstract class BlendMod extends PoseMod {
    public final TrackMod a, b;

    public BlendMod(ModOwner owner, Skeleton skel, TrackMod a, TrackMod b) {
	skel.super(owner);
	this.a = a;
	this.b = b;
	blend(factor());
    }

    public BlendMod(ModOwner owner, Skeleton skel, ResPose a, ResPose b) {
	this(owner, skel, a.forskel(owner, skel, a.defmode), b.forskel(owner, skel, b.defmode));
    }

    protected abstract float factor();

    private static float[] qset(float[] d, float[] s) {
	d[0] = s[0];
	d[1] = s[1];
	d[2] = s[2];
	d[3] = s[3];
	return(d);
    }

    /*
     * XXX: Should not be duplicated, but apparently Skeleton.qqslerp was private. :(
     *
     * Arguably though, the whole blending thing should have some utility function directly in Skeleton.
     */
    private static float[] qqslerp(float[] d, float[] a, float[] b, float t) {
	float aw = a[0], ax = a[1], ay = a[2], az = a[3];
	float bw = b[0], bx = b[1], by = b[2], bz = b[3];
	if((aw == bw) && (ax == bx) && (ay == by) && (az == bz))
	    return(qset(d, a));
	float cos = (aw * bw) + (ax * bx) + (ay * by) + (az * bz);
	if(cos < 0) {
	    bw = -bw; bx = -bx; by = -by; bz = -bz;
	    cos = -cos;
	}
	float d0, d1;
	if(cos > 0.9999f) {
	    /* Reasonable threshold? Is this function even critical
	     * for performance? */
	    d0 = 1.0f - t; d1 = t;
	} else {
	    float da = (float)Math.acos(Utils.clip(cos, 0.0, 1.0));
	    float nf = 1.0f / (float)Math.sin(da);
	    d0 = (float)Math.sin((1.0f - t) * da) * nf;
	    d1 = (float)Math.sin(t * da) * nf;
	}
	d[0] = (d0 * aw) + (d1 * bw);
	d[1] = (d0 * ax) + (d1 * bx);
	d[2] = (d0 * ay) + (d1 * by);
	d[3] = (d0 * az) + (d1 * bz);
	return(d);
    }

    public void blend(float f) {
	float F = 1.0f - f;
	for(int i = 0; i < skel().blist.length; i++) {
	    qqslerp(lrot[i], a.lrot[i], b.lrot[i], f);
	    lpos[i][0] = (a.lpos[i][0] * F) + (b.lpos[i][0] * f);
	    lpos[i][1] = (a.lpos[i][1] * F) + (b.lpos[i][1] * f);
	    lpos[i][2] = (a.lpos[i][2] * F) + (b.lpos[i][2] * f);
	}
    }

    public boolean tick(float dt) {
	a.tick(dt);
	b.tick(dt);
	blend(factor());
	return(false);
    }

    public boolean stat() {return(false);}
    public boolean done() {return(false);}
}

src 	  AUtils.java /* Preprocessed source code */
package haven.res.lib.anim;

import java.util.*;
import haven.*;
import haven.Skeleton.*;

public class AUtils {
    public static PoseMod combine(Skeleton skel, PoseMod... mods) {
	int n = 0;
	PoseMod last = null;
	for(PoseMod mod : mods) {
	    if(mod != null) {
		last = mod;
		n++;
	    }
	}
	if(n == 0)
	    return(skel.nilmod());
	if(n == 1)
	    return(last);
	if(n != mods.length) {
	    PoseMod[] buf = new PoseMod[n];
	    for(int i = 0, o = 0; i < mods.length; i++) {
		if(mods[i] != null)
		    buf[o++] = mods[i];
	    }
	    mods = buf;
	}
	return(Skeleton.combine(mods));
    }

    public static PoseMod combine(Skeleton skel, Collection<PoseMod> mods) {
	return(combine(skel, mods.toArray(new PoseMod[0])));
    }
}
code �	  haven.res.lib.anim.BlendMod ����   4 r
 9 :
  ;	  <	  =
  >
  ?	 % @
 % A
  B
  C?�r
 D E
 F G
 F H
  I	 J K	  L	  L
  M	  N	  N
  O P Q a S TrackMod InnerClasses Lhaven/Skeleton$TrackMod; b <init> T ModOwner ^(Lhaven/Skeleton$ModOwner;Lhaven/Skeleton;Lhaven/Skeleton$TrackMod;Lhaven/Skeleton$TrackMod;)V Code LineNumberTable U ResPose \(Lhaven/Skeleton$ModOwner;Lhaven/Skeleton;Lhaven/Skeleton$ResPose;Lhaven/Skeleton$ResPose;)V factor ()F qset ([F[F)[F qqslerp ([F[F[FF)[F StackMapTable V blend (F)V tick (F)Z stat ()Z done 
SourceFile BlendMod.java W X Y  Z     ( ) 0 1 [ \ ] ^  " * + _ ` a b c d e d f g h i l m n , - o n 2 3 haven/res/lib/anim/BlendMod haven/Skeleton$PoseMod PoseMod haven/Skeleton$TrackMod haven/Skeleton$ModOwner haven/Skeleton$ResPose [F java/lang/Object getClass ()Ljava/lang/Class; ,(Lhaven/Skeleton;Lhaven/Skeleton$ModOwner;)V defmode Lhaven/WrapMode; forskel T(Lhaven/Skeleton$ModOwner;Lhaven/Skeleton;Lhaven/WrapMode;)Lhaven/Skeleton$TrackMod; haven/Utils clip (DDD)D java/lang/Math acos (D)D sin skel ()Lhaven/Skeleton; haven/Skeleton blist p Bone [Lhaven/Skeleton$Bone; lrot [[F lpos haven/Skeleton$Bone 
anim.cjava!                	   "  #   G     *,Y� W+� *-� *� **� � �    $                  '  #   9     *+,-+,-� � +,� � � 	�    $   
       ( )   
 * +  #   B     *+0Q*+0Q*+0Q*+0Q*�    $                
 , -  #  �    +08+08+08+08,08,08	,08
,08�� !	�� 
�� �� 	*+� 
�j	jb
jbjb8�� v8	v8	
v8
v8v8�� %f8%8� :�� � �8�� �n8%fj�� �j8%j�� �j8*jjbQ*j	jbQ*j
jbQ*jjbQ*�    .   % � N  / / /  � 8� 6 $   N    %  & ( ' H ( N ) g * n + � , � / � 2 � 4 � 5 � 6 � 7 � 9 � : � ; � <	 =  0 1  #   �     �#fE>*� � �� �*� 2*� � 2*� � 2#� W*� 2*� � 20$j*� � 20#jbQ*� 2*� � 20$j*� � 20#jbQ*� 2*� � 20$j*� � 20#jbQ���k�    .   
 � � � $   "    A  B  C / D R E u F � B � H  2 3  #   @     *� #� W*� #� W**� � �    $       K 	 L  M  N  4 5  #        �    $       Q  6 5  #        �    $       R  7    q    *   J     J !	 % J & 	  J R j J k 	code �  haven.res.lib.anim.AUtils ����   4 -
 	 
   
      !
  " # $ <init> ()V Code LineNumberTable combine PoseMod InnerClasses C(Lhaven/Skeleton;[Lhaven/Skeleton$PoseMod;)Lhaven/Skeleton$PoseMod; StackMapTable %  @(Lhaven/Skeleton;Ljava/util/Collection;)Lhaven/Skeleton$PoseMod; 	Signature Z(Lhaven/Skeleton;Ljava/util/Collection<Lhaven/Skeleton$PoseMod;>;)Lhaven/Skeleton$PoseMod; 
SourceFile AUtils.java 
  % & ' haven/Skeleton$PoseMod  ( ) * + [Lhaven/Skeleton$PoseMod;   haven/res/lib/anim/AUtils java/lang/Object haven/Skeleton nilmod ()Lhaven/Skeleton$PoseMod; 3([Lhaven/Skeleton$PoseMod;)Lhaven/Skeleton$PoseMod; java/util/Collection toArray (([Ljava/lang/Object;)[Ljava/lang/Object; 
anim.cjava !  	       
           *� �           U �           x=N+:�66� 2:� 	N������ *� �� -�+�� 2� :66+�� +2� �+2S����L+� �       - 	�        � �  � �     N    W  X  Y  Z " [ % \ ( Y . _ 2 ` 7 a < b > c D d J e W f ^ g j e p i s k 	       *     *+� �  � � �           o           ,    
    codeentry     