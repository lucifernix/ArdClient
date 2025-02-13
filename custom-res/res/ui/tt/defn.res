Haven Resource 1 src �   DynName.java /* Preprocessed source code */
package haven.res.ui.tt.defn;

import haven.*;

public interface DynName {
    public String name();
}

/* >tt: haven.res.ui.tt.defn.DefName */
src e  DefName.java /* Preprocessed source code */
package haven.res.ui.tt.defn;

import haven.*;

public class DefName implements ItemInfo.InfoFactory {
    public static String getname(ItemInfo.Owner owner) {
	if(owner instanceof ItemInfo.SpriteOwner) {
	    GSprite spr = ((ItemInfo.SpriteOwner)owner).sprite();
	    if(spr instanceof DynName)
		return(((DynName)spr).name());
	}
	if(!(owner instanceof ItemInfo.ResOwner))
	    return(null);
	Resource res = ((ItemInfo.ResOwner)owner).resource();
	Resource.Tooltip tt = res.layer(Resource.tooltip);
	if(tt == null)
	    throw(new RuntimeException("Item resource " + res + " is missing default tooltip"));
	return(tt.t);
    }

    public ItemInfo build(ItemInfo.Owner owner, ItemInfo.Raw raw, Object... args) {
	String nm = getname(owner);
	if(nm == null)
	    return(null);
	return(new ItemInfo.Name(owner, nm));
    }
}
code �   haven.res.ui.tt.defn.DynName ����   4 
   name ()Ljava/lang/String; 
SourceFile DynName.java haven/res/ui/tt/defn/DynName java/lang/Object 
defn.cjava                 	code   haven.res.ui.tt.defn.DefName ����   4 i
  . 0  2 3  4 5  7	 8 9
 8 : ; = >
  . ?
  @
  A B
  C
  D	 
 E
  F G
  I J K L <init> ()V Code LineNumberTable getname N Owner InnerClasses *(Lhaven/ItemInfo$Owner;)Ljava/lang/String; StackMapTable O ; build P Raw O(Lhaven/ItemInfo$Owner;Lhaven/ItemInfo$Raw;[Ljava/lang/Object;)Lhaven/ItemInfo; Q 
SourceFile DefName.java   R haven/ItemInfo$SpriteOwner SpriteOwner S T haven/res/ui/tt/defn/DynName U V haven/ItemInfo$ResOwner ResOwner W X O Y Z [ ^ haven/Resource$Tooltip Tooltip java/lang/RuntimeException java/lang/StringBuilder Item resource  _ ` _ a  is missing default tooltip b V  c d e  # haven/ItemInfo$Name Name  f haven/res/ui/tt/defn/DefName java/lang/Object haven/ItemInfo$InfoFactory InfoFactory haven/ItemInfo$Owner haven/Resource haven/ItemInfo$Raw java/lang/String haven/ItemInfo sprite ()Lhaven/GSprite; name ()Ljava/lang/String; resource ()Lhaven/Resource; tooltip Ljava/lang/Class; layer g Layer )(Ljava/lang/Class;)Lhaven/Resource$Layer; append -(Ljava/lang/String;)Ljava/lang/StringBuilder; -(Ljava/lang/Object;)Ljava/lang/StringBuilder; toString (Ljava/lang/String;)V t Ljava/lang/String; +(Lhaven/ItemInfo$Owner;Ljava/lang/String;)V haven/Resource$Layer 
defn.cjava !                    *� �           
 	  #     �     i*� � *� �  L+� � +� �  �*� � �*� �  L+� � 	� 
M,� #� Y� Y� � +� � � � �,� �    $    "� 8 % &    .           "  )  +  5  @  D  d  � ' *     J     +� :� �� Y+� �    $    �  +                ,    h "   B    / !	 ( / ) 	  / 1	  / 6	 
 8 <   / H 	  / M	 \ 8 ]codeentry #   tt haven.res.ui.tt.defn.DefName   