function [Fcv,Flv,FlvR] = fValue(data,R)
% Function to calculate F-value

numNeurons=length(data);

cont=0;
for i=1:numNeurons
    if(length(data(i).isis)>0 && ~sum(isnan(data(i).lv)))
        cont=cont+1;
        breaks=find(data(i).isis<0);
        numSpkTrains=length(breaks)+1;
        m_cv(cont)=mean(data(i).cv);
        s_cv(cont)=var(data(i).cv);
        m_lv(cont)=mean(data(i).lv);
        s_lv(cont)=var(data(i).lv);
        m_lvR(:,cont)=mean(data(i).lvR,2);
        s_lvR(:,cont)=var(data(i).lvR,0,2);
    end
end

mm_cv=mean(m_cv);
mm_lv=mean(m_lv);
mm_lvR=mean(m_lvR,2);

factor=numSpkTrains*cont/(cont-1);

Fcv=factor*sum((m_cv-mm_cv).^2)/sum(s_cv.^2);
Flv=factor*sum((m_lv-mm_lv).^2)/sum(s_lv.^2);
for k=1:length(R)
    FlvR(k)=factor*sum((m_lvR(k,:)-mm_lvR(k)).^2)/sum(s_lvR(k,:).^2);
end
